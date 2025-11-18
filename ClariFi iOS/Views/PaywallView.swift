import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Premium")
                            .font(.title.bold())
                        
                        Text("Unlock advanced insights and forecasting")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    
                    // Premium Features
                    VStack(spacing: 16) {
                        PremiumFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Cashflow Forecasting",
                            description: "Predict future spending with confidence intervals"
                        )
                        
                        PremiumFeatureRow(
                            icon: "slider.horizontal.3",
                            title: "Scenario Planning",
                            description: "Model spending changes and see future impact"
                        )
                        
                        PremiumFeatureRow(
                            icon: "brain.head.profile",
                            title: "Advanced Analytics",
                            description: "Deep insights into spending patterns and trends"
                        )
                        
                        PremiumFeatureRow(
                            icon: "sparkles",
                            title: "Premium Insights",
                            description: "Personalized recommendations for financial health"
                        )
                        
                        PremiumFeatureRow(
                            icon: "chart.bar.xaxis",
                            title: "Trend Predictions",
                            description: "AI-powered predictions of future spending"
                        )
                        
                        PremiumFeatureRow(
                            icon: "lock.shield",
                            title: "Privacy First",
                            description: "All processing remains on-device"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Subscription Options
                    if subscriptionService.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                                SubscriptionOptionCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Purchase Button
                    if let product = selectedProduct {
                        Button(action: {
                            Task {
                                await purchaseProduct(product)
                            }
                        }) {
                            HStack {
                                if subscriptionService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Subscribe Now")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(subscriptionService.isLoading)
                        .padding(.horizontal)
                    }
                    
                    // Restore Purchases
                    Button(action: {
                        Task {
                            await restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(subscriptionService.isLoading)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("Subscription auto-renews unless cancelled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // Open terms
                            }
                            .font(.caption)
                            
                            Button("Privacy Policy") {
                                // Open privacy policy
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            Analytics.track(.paywallViewed)
            
            do {
                let products = try await subscriptionService.loadProducts()
                // Auto-select the first product
                if let first = products.first {
                    selectedProduct = first
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        do {
            let transaction = try await subscriptionService.purchase(product)
            if transaction != nil {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func restorePurchases() async {
        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.isPremiumActive {
                dismiss()
            } else {
                errorMessage = "No active subscriptions found"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Subscription Option Card
struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var savingsText: String? {
        // Calculate savings for yearly vs monthly
        if product.id.contains("yearly") {
            let monthlyEquivalent = product.price / 12
            return "Save \(monthlyEquivalent.formatted(.currency(code: product.priceFormatStyle.currencyCode))) per month"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let savings = savingsText {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    if product.id.contains("yearly") {
                        Text("per year")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("per month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

#Preview {
    PaywallView()
}
