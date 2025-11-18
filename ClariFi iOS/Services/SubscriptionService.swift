import Foundation
import StoreKit

// MARK: - Subscription Product IDs
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "com.clarifi.premium.monthly"
    case yearly = "com.clarifi.premium.yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly Premium"
        case .yearly: return "Yearly Premium"
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus {
    case notSubscribed
    case subscribed(expirationDate: Date)
    case expired(gracePeriod: Bool)
    case pending
}

// MARK: - Subscription Service Protocol
protocol SubscriptionServiceProtocol {
    var subscriptionStatus: SubscriptionStatus { get }
    var isPremiumActive: Bool { get }
    
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> StoreKit.Transaction?
    func restorePurchases() async throws
    func checkSubscriptionStatus() async
}

// MARK: - Subscription Service Implementation
class SubscriptionService: ObservableObject, SubscriptionServiceProtocol {
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    private var updateListenerTask: Task<Void, Error>?
    
    var isPremiumActive: Bool {
        switch subscriptionStatus {
        case .subscribed, .expired(gracePeriod: true):
            return true
        case .notSubscribed, .expired(gracePeriod: false), .pending:
            return false
        }
    }
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Safe Initialization for Development
    private func safeInitialize() {
        // Only initialize StoreKit when enabled in configuration
        guard Configuration.isStoreKitEnabled else {
            print("SubscriptionService: StoreKit disabled in configuration")
            return
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async throws -> [Product] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIds = SubscriptionProduct.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIds)
            
            // Sort by price (lowest first)
            let sortedProducts = products.sorted { $0.price < $1.price }
            
            await MainActor.run {
                self.availableProducts = sortedProducts
            }
            
            return sortedProducts
        } catch {
            let subscriptionError = SubscriptionError.productLoadFailed(error)
            await MainActor.run {
                self.error = subscriptionError
            }
            throw subscriptionError
        }
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        defer { isLoading = false }
        
        Analytics.track(.subscriptionStarted, properties: [
            "product_id": product.id
        ])
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update subscription status
                await checkSubscriptionStatus()
                
                Analytics.track(.subscriptionCompleted, properties: [
                    "product_id": product.id,
                    "transaction_id": String(transaction.id)
                ])
                
                // Finish the transaction
                await transaction.finish()
                
                return transaction
                
            case .userCancelled:
                Analytics.track(.subscriptionFailed, properties: [
                    "reason": "user_cancelled",
                    "product_id": product.id
                ])
                return nil
                
            case .pending:
                await MainActor.run {
                    self.subscriptionStatus = .pending
                }
                Analytics.track(.subscriptionFailed, properties: [
                    "reason": "pending",
                    "product_id": product.id
                ])
                return nil
                
            @unknown default:
                return nil
            }
        } catch {
            let subscriptionError = SubscriptionError.purchaseFailed(error)
            await MainActor.run {
                self.error = subscriptionError
            }
            Analytics.track(.subscriptionFailed, properties: [
                "reason": "error",
                "error": error.localizedDescription,
                "product_id": product.id
            ])
            error.track(context: ["component": "subscription"])
            throw subscriptionError
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            Analytics.track(.subscriptionRestored)
        } catch {
            let subscriptionError = SubscriptionError.restoreFailed(error)
            await MainActor.run {
                self.error = subscriptionError
            }
            error.track(context: ["component": "subscription_restore"])
            throw subscriptionError
        }
    }
    
    // MARK: - Check Subscription Status
    func checkSubscriptionStatus() async {
        // Skip StoreKit operations when disabled in configuration
        guard Configuration.isStoreKitEnabled else {
            print("SubscriptionService: Skipping subscription check - StoreKit disabled")
            return
        }
        var activeSubscription: StoreKit.Transaction?
        var expirationDate: Date?
        
        // Check for active subscriptions
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is a subscription product
                if SubscriptionProduct.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    activeSubscription = transaction
                    
                    // Get expiration date
                    if let expiration = transaction.expirationDate {
                        expirationDate = expiration
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        await MainActor.run {
            if activeSubscription != nil {
                if let expiration = expirationDate {
                    if expiration > Date() {
                        self.subscriptionStatus = .subscribed(expirationDate: expiration)
                    } else {
                        // Check if in grace period (7 days)
                        let gracePeriodEnd = expiration.addingTimeInterval(7 * 24 * 60 * 60)
                        let inGracePeriod = Date() < gracePeriodEnd
                        self.subscriptionStatus = .expired(gracePeriod: inGracePeriod)
                    }
                } else {
                    self.subscriptionStatus = .subscribed(expirationDate: Date.distantFuture)
                }
            } else {
                self.subscriptionStatus = .notSubscribed
            }
        }
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Skip transaction listening when StoreKit is disabled
            guard Configuration.isStoreKitEnabled else {
                print("SubscriptionService: Skipping transaction listener - StoreKit disabled")
                return
            }
            
            do {
                for await result in StoreKit.Transaction.updates {
                    do {
                        let transaction = try await self.checkVerified(result)
                        
                        await self.checkSubscriptionStatus()
                        
                        await transaction.finish()
                    } catch {
                        print("Transaction verification failed: \(error)")
                        // Continue listening even if one transaction fails
                    }
                }
            } catch {
                print("Transaction listener error: \(error)")
                // Don't crash the app if StoreKit fails
            }
        }
    }
    
    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Subscription Error
enum SubscriptionError: LocalizedError {
    case productLoadFailed(Error)
    case purchaseFailed(Error)
    case restoreFailed(Error)
    case verificationFailed
    case notSubscribed
    
    var errorDescription: String? {
        switch self {
        case .productLoadFailed(let error):
            return "Failed to load subscription products: \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Failed to restore purchases: \(error.localizedDescription)"
        case .verificationFailed:
            return "Failed to verify purchase"
        case .notSubscribed:
            return "Premium subscription required"
        }
    }
}
