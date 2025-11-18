//
//  PremiumGatingIntegrationTests.swift
//  ClariFi iOSTests
//
//  Integration tests for premium feature gating workflows
//

import XCTest
import CoreData
@testable import ClariFi_iOS

@MainActor
class PremiumGatingIntegrationTests: XCTestCase {
    
    var subscriptionService: MockSubscriptionService!
    var subscriptionViewModel: SubscriptionViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock subscription service
        subscriptionService = MockSubscriptionService()
        subscriptionViewModel = SubscriptionViewModel(subscriptionService: subscriptionService)
    }
    
    override func tearDown() async throws {
        subscriptionService = nil
        subscriptionViewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Premium Feature Access Tests
    
    func testPremiumFeatureAccessForSubscribedUsers() async throws {
        // Given: User has active premium subscription
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        
        // When: User attempts to access premium feature
        var actionExecuted = false
        subscriptionViewModel.requirePremium {
            actionExecuted = true
        }
        
        // Then: Action should execute without showing paywall
        XCTAssertTrue(actionExecuted, "Premium action should execute for subscribed users")
        XCTAssertFalse(subscriptionViewModel.showPaywall, "Paywall should not be shown for subscribed users")
    }
    
    func testPremiumFeatureAccessForFreeUsers() async throws {
        // Given: User does not have premium subscription
        subscriptionService.subscriptionStatus = .notSubscribed
        
        // When: User attempts to access premium feature
        var actionExecuted = false
        subscriptionViewModel.requirePremium {
            actionExecuted = true
        }
        
        // Then: Action should not execute and paywall should be shown
        XCTAssertFalse(actionExecuted, "Premium action should not execute for free users")
        XCTAssertTrue(subscriptionViewModel.showPaywall, "Paywall should be shown for free users")
    }
    
    func testPremiumFeatureAccessDuringGracePeriod() async throws {
        // Given: User subscription expired but in grace period
        subscriptionService.subscriptionStatus = .expired(gracePeriod: true)
        
        // When: User attempts to access premium feature
        var actionExecuted = false
        subscriptionViewModel.requirePremium {
            actionExecuted = true
        }
        
        // Then: Action should execute (grace period allows access)
        XCTAssertTrue(actionExecuted, "Premium action should execute during grace period")
        XCTAssertFalse(subscriptionViewModel.showPaywall, "Paywall should not be shown during grace period")
    }
    
    func testPremiumFeatureAccessAfterGracePeriod() async throws {
        // Given: User subscription expired and grace period ended
        subscriptionService.subscriptionStatus = .expired(gracePeriod: false)
        
        // When: User attempts to access premium feature
        var actionExecuted = false
        subscriptionViewModel.requirePremium {
            actionExecuted = true
        }
        
        // Then: Action should not execute and paywall should be shown
        XCTAssertFalse(actionExecuted, "Premium action should not execute after grace period")
        XCTAssertTrue(subscriptionViewModel.showPaywall, "Paywall should be shown after grace period")
    }
    
    func testPremiumFeatureAccessWithPendingPurchase() async throws {
        // Given: User has pending purchase
        subscriptionService.subscriptionStatus = .pending
        
        // When: User attempts to access premium feature
        var actionExecuted = false
        subscriptionViewModel.requirePremium {
            actionExecuted = true
        }
        
        // Then: Action should not execute (pending is not active)
        XCTAssertFalse(actionExecuted, "Premium action should not execute with pending purchase")
        XCTAssertTrue(subscriptionViewModel.showPaywall, "Paywall should be shown with pending purchase")
    }
    
    // MARK: - Subscription Status Change Tests
    
    func testSubscriptionStatusChangeFromFreeToSubscribed() async throws {
        // Given: User starts as free user
        subscriptionService.subscriptionStatus = .notSubscribed
        XCTAssertFalse(subscriptionViewModel.isPremiumActive)
        
        // When: User subscribes
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        
        // Then: Premium status should be active
        XCTAssertTrue(subscriptionViewModel.isPremiumActive)
        XCTAssertTrue(subscriptionViewModel.isPremium)
    }
    
    func testSubscriptionStatusChangeFromSubscribedToExpired() async throws {
        // Given: User has active subscription
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        XCTAssertTrue(subscriptionViewModel.isPremiumActive)
        
        // When: Subscription expires without grace period
        subscriptionService.subscriptionStatus = .expired(gracePeriod: false)
        
        // Then: Premium status should be inactive
        XCTAssertFalse(subscriptionViewModel.isPremiumActive)
    }
    
    func testSubscriptionStatusChangeFromExpiredToSubscribed() async throws {
        // Given: User has expired subscription
        subscriptionService.subscriptionStatus = .expired(gracePeriod: false)
        XCTAssertFalse(subscriptionViewModel.isPremiumActive)
        
        // When: User resubscribes
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        
        // Then: Premium status should be active again
        XCTAssertTrue(subscriptionViewModel.isPremiumActive)
    }
    
    // MARK: - Feature Check Tests
    
    func testCheckFeatureAccessForAllPremiumFeatures() async throws {
        // Given: User has active subscription
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        
        // When: Checking access for each premium feature
        for feature in PremiumFeature.allCases {
            let hasAccess = subscriptionViewModel.checkFeatureAccess(feature: feature)
            
            // Then: All features should be accessible
            XCTAssertTrue(hasAccess, "Feature \(feature.rawValue) should be accessible for premium users")
        }
    }
    
    func testCheckFeatureAccessForFreeUser() async throws {
        // Given: User does not have subscription
        subscriptionService.subscriptionStatus = .notSubscribed
        
        // When: Checking access for each premium feature
        for feature in PremiumFeature.allCases {
            let hasAccess = subscriptionViewModel.checkFeatureAccess(feature: feature)
            
            // Then: No features should be accessible
            XCTAssertFalse(hasAccess, "Feature \(feature.rawValue) should not be accessible for free users")
        }
    }
    
    // MARK: - Subscription Status Text Tests
    
    func testSubscriptionStatusTextForNotSubscribed() async throws {
        // Given: User is not subscribed
        subscriptionService.subscriptionStatus = .notSubscribed
        
        // When: Getting status text
        let statusText = subscriptionViewModel.subscriptionStatusText
        
        // Then: Should show not subscribed
        XCTAssertEqual(statusText, "Not Subscribed")
    }
    
    func testSubscriptionStatusTextForActiveSubscription() async throws {
        // Given: User has active subscription
        let expirationDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: expirationDate)
        
        // When: Getting status text
        let statusText = subscriptionViewModel.subscriptionStatusText
        
        // Then: Should show expiration date
        XCTAssertTrue(statusText.contains("Active until"))
    }
    
    func testSubscriptionStatusTextForExpiredWithGracePeriod() async throws {
        // Given: User subscription expired with grace period
        subscriptionService.subscriptionStatus = .expired(gracePeriod: true)
        
        // When: Getting status text
        let statusText = subscriptionViewModel.subscriptionStatusText
        
        // Then: Should show grace period status
        XCTAssertEqual(statusText, "Expired (Grace Period)")
    }
    
    func testSubscriptionStatusTextForExpiredWithoutGracePeriod() async throws {
        // Given: User subscription expired without grace period
        subscriptionService.subscriptionStatus = .expired(gracePeriod: false)
        
        // When: Getting status text
        let statusText = subscriptionViewModel.subscriptionStatusText
        
        // Then: Should show expired status
        XCTAssertEqual(statusText, "Expired")
    }
    
    func testSubscriptionStatusTextForPending() async throws {
        // Given: User has pending purchase
        subscriptionService.subscriptionStatus = .pending
        
        // When: Getting status text
        let statusText = subscriptionViewModel.subscriptionStatusText
        
        // Then: Should show pending status
        XCTAssertEqual(statusText, "Purchase Pending")
    }
    
    // MARK: - Multiple Feature Access Tests
    
    func testMultiplePremiumFeatureAccessAttempts() async throws {
        // Given: User is not subscribed
        subscriptionService.subscriptionStatus = .notSubscribed
        
        // When: User attempts to access multiple premium features
        var firstActionExecuted = false
        var secondActionExecuted = false
        
        subscriptionViewModel.requirePremium {
            firstActionExecuted = true
        }
        
        // Reset paywall state
        subscriptionViewModel.showPaywall = false
        
        subscriptionViewModel.requirePremium {
            secondActionExecuted = true
        }
        
        // Then: Neither action should execute
        XCTAssertFalse(firstActionExecuted)
        XCTAssertFalse(secondActionExecuted)
        XCTAssertTrue(subscriptionViewModel.showPaywall)
    }
    
    func testPremiumFeatureAccessAfterSubscribing() async throws {
        // Given: User starts as free user and attempts premium feature
        subscriptionService.subscriptionStatus = .notSubscribed
        
        var firstActionExecuted = false
        subscriptionViewModel.requirePremium {
            firstActionExecuted = true
        }
        
        XCTAssertFalse(firstActionExecuted)
        XCTAssertTrue(subscriptionViewModel.showPaywall)
        
        // When: User subscribes
        subscriptionService.subscriptionStatus = .subscribed(expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60))
        subscriptionViewModel.showPaywall = false
        
        // And: User attempts premium feature again
        var secondActionExecuted = false
        subscriptionViewModel.requirePremium {
            secondActionExecuted = true
        }
        
        // Then: Second action should execute
        XCTAssertTrue(secondActionExecuted)
        XCTAssertFalse(subscriptionViewModel.showPaywall)
    }
}

// MARK: - Mock Subscription Service

class MockSubscriptionService: SubscriptionServiceProtocol {
    var subscriptionStatus: SubscriptionStatus = .notSubscribed
    var isPremiumActive: Bool {
        switch subscriptionStatus {
        case .subscribed, .expired(gracePeriod: true):
            return true
        case .notSubscribed, .expired(gracePeriod: false), .pending:
            return false
        }
    }
    
    func loadProducts() async throws -> [Product] {
        return []
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        return nil
    }
    
    func restorePurchases() async throws {
        // Mock implementation
    }
    
    func checkSubscriptionStatus() async {
        // Mock implementation
    }
}
