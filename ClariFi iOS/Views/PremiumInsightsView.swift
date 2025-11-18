import SwiftUI
import CoreData

struct PremiumInsightsView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            Group {
                if subscriptionViewModel.isPremiumActive {
                    premiumContent
                } else {
                    PremiumFeatureLock(feature: .premiumInsights)
                }
            }
            .navigationTitle("Premium Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    subscriptionStatusButton
                }
            }
        }
    }
    
    private var premiumContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Premium Badge
                premiumBadge
                
                // Feature Cards
                NavigationLink(destination: CashflowForecastView(context: viewContext)) {
                    PremiumFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Cashflow Forecasting",
                        description: "See your financial future with AI-powered predictions",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: ScenarioPlanningView(context: viewContext)) {
                    PremiumFeatureCard(
                        icon: "slider.horizontal.3",
                        title: "Scenario Planning",
                        description: "Model spending changes and see their impact",
                        color: .purple
                    )
                }
                
                NavigationLink(destination: AdvancedAnalyticsView(context: viewContext)) {
                    PremiumFeatureCard(
                        icon: "brain.head.profile",
                        title: "Advanced Analytics",
                        description: "Deep insights into your spending patterns",
                        color: .green
                    )
                }
                
                NavigationLink(destination: TrendPredictionsView(context: viewContext)) {
                    PremiumFeatureCard(
                        icon: "chart.bar.xaxis",
                        title: "Trend Predictions",
                        description: "AI-powered predictions of future spending",
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }
    
    private var premiumBadge: some View {
        HStack {
            Image(systemName: "crown.fill")
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Premium Active")
                    .font(.headline)
                
                Text(subscriptionViewModel.subscriptionStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    private var subscriptionStatusButton: some View {
        Button(action: {
            subscriptionViewModel.showPaywall = true
        }) {
            Image(systemName: "crown.fill")
                .foregroundColor(.yellow)
        }
    }
}

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Advanced Analytics View (Placeholder)
struct AdvancedAnalyticsView: View {
    let context: NSManagedObjectContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Advanced Analytics")
                    .font(.title.bold())
                
                Text("Deep statistical analysis of your spending patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Placeholder for advanced analytics
                VStack(spacing: 16) {
                    analyticsCard(
                        title: "Spending Velocity",
                        value: "12% faster",
                        trend: "up",
                        description: "Your spending rate has increased compared to last month"
                    )
                    
                    analyticsCard(
                        title: "Category Diversity",
                        value: "8 categories",
                        trend: "stable",
                        description: "You're spending across a healthy variety of categories"
                    )
                    
                    analyticsCard(
                        title: "Budget Adherence",
                        value: "87%",
                        trend: "up",
                        description: "You're staying within budget more consistently"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Advanced Analytics")
    }
    
    private func analyticsCard(title: String, value: String, trend: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: trendIcon(trend))
                    .foregroundColor(trendColor(trend))
            }
            
            Text(value)
                .font(.title.bold())
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func trendIcon(_ trend: String) -> String {
        switch trend {
        case "up": return "arrow.up.right"
        case "down": return "arrow.down.right"
        default: return "arrow.right"
        }
    }
    
    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "up": return .green
        case "down": return .red
        default: return .gray
        }
    }
}

// MARK: - Trend Predictions View (Placeholder)
struct TrendPredictionsView: View {
    let context: NSManagedObjectContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Trend Predictions")
                    .font(.title.bold())
                
                Text("AI-powered predictions of your future spending patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Placeholder for trend predictions
                VStack(spacing: 16) {
                    predictionCard(
                        category: "Dining",
                        prediction: "Likely to increase by 15%",
                        confidence: 0.85,
                        reason: "Based on recent patterns and seasonal trends"
                    )
                    
                    predictionCard(
                        category: "Transportation",
                        prediction: "Expected to remain stable",
                        confidence: 0.92,
                        reason: "Consistent spending pattern over past 6 months"
                    )
                    
                    predictionCard(
                        category: "Entertainment",
                        prediction: "May decrease by 10%",
                        confidence: 0.78,
                        reason: "Historical pattern shows reduction in this period"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Trend Predictions")
    }
    
    private func predictionCard(category: String, prediction: String, confidence: Float, reason: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(prediction)
                .font(.subheadline.bold())
                .foregroundColor(.blue)
            
            Text(reason)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PremiumInsightsView()
        .environmentObject(SubscriptionViewModel())
}
