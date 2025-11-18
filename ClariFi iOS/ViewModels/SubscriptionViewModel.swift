import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: BaseViewModel {
    @Published var subscriptionService: SubscriptionService
    @Published var showPaywall = false
    
    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
        super.init()
    }
    
    convenience override init() {
        self.init(subscriptionService: SubscriptionService())
    }
    
    var isPremiumActive: Bool {
        subscriptionService.isPremiumActive
    }
    
    var isPremium: Bool {
        subscriptionService.isPremiumActive
    }
    
    var subscriptionStatusText: String {
        switch subscriptionService.subscriptionStatus {
        case .notSubscribed:
            return "Not Subscribed"
        case .subscribed(let expirationDate):
            return "Active until \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
        case .expired(let gracePeriod):
            return gracePeriod ? "Expired (Grace Period)" : "Expired"
        case .pending:
            return "Purchase Pending"
        }
    }
    
    func requirePremium(action: @escaping () -> Void) {
        if isPremiumActive {
            action()
        } else {
            showPaywall = true
        }
    }
    
    func checkFeatureAccess(feature: PremiumFeature) -> Bool {
        return isPremiumActive
    }
}

// MARK: - Premium Features
enum PremiumFeature: String, CaseIterable {
    case cashflowForecasting = "Cashflow Forecasting"
    case scenarioPlanning = "Scenario Planning"
    case advancedAnalytics = "Advanced Analytics"
    case premiumInsights = "Premium Insights"
    case trendPredictions = "Trend Predictions"
    
    var icon: String {
        switch self {
        case .cashflowForecasting:
            return "chart.line.uptrend.xyaxis"
        case .scenarioPlanning:
            return "slider.horizontal.3"
        case .advancedAnalytics:
            return "brain.head.profile"
        case .premiumInsights:
            return "sparkles"
        case .trendPredictions:
            return "chart.bar.xaxis"
        }
    }
    
    var description: String {
        switch self {
        case .cashflowForecasting:
            return "Predict future spending with confidence intervals based on your transaction history"
        case .scenarioPlanning:
            return "Model different spending scenarios and see their impact on your budget"
        case .advancedAnalytics:
            return "Deep dive into spending patterns with advanced statistical analysis"
        case .premiumInsights:
            return "Get personalized recommendations powered by advanced algorithms"
        case .trendPredictions:
            return "AI-powered predictions of future spending trends"
        }
    }
}

// MARK: - Premium Feature Lock View
struct PremiumFeatureLock: View {
    let feature: PremiumFeature
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(feature.rawValue)
                .font(.title2.bold())
            
            Text(feature.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                subscriptionViewModel.showPaywall = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}
