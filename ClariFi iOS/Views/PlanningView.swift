//
//  PlanningView.swift
//  ClariFi iOS
//
//  Consolidated view for Budget management and App settings
//

import SwiftUI

struct PlanningView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    
    // Cache ViewModels to prevent recreation and flickering
    @State private var budgetViewModel: BudgetViewModel?
    @State private var budgetCreationViewModel: BudgetCreationViewModel?
    @State private var navigationSelection: PlanningDestination?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                // Budget Management Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget Management")
                        .headlineStyle()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                        .accessibleHeading(.h2)
                    
                    VStack(spacing: 0) {
                        NavigationLink(
                            destination: Group {
                            if let budgetViewModel = budgetViewModel {
                                BudgetView(viewModel: budgetViewModel)
                            } else {
                                ProgressView("Loading...")
                            }
                        },
                            tag: PlanningDestination.currentBudget,
                            selection: $navigationSelection
                        ) {
                            HStack {
                                Label("Current Budget", systemImage: "target")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("View current budget")
                        .accessibilityHint("See your current budget status and spending")
                        
                        Divider()
                            .padding(.leading)
                        
                        NavigationLink(
                            destination: Group {
                            if let budgetCreationViewModel = budgetCreationViewModel {
                                BudgetCreationView(viewModel: budgetCreationViewModel)
                            } else {
                                ProgressView("Loading...")
                            }
                        },
                            tag: PlanningDestination.createBudget,
                            selection: $navigationSelection
                        ) {
                            HStack {
                                Label("Create New Budget", systemImage: "plus.circle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("Create new budget")
                        .accessibilityHint("Set up a new budget for your finances")
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Premium Features Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Premium Features")
                        .headlineStyle()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                        .accessibleHeading(.h2)
                    
                    VStack(spacing: 0) {
                        // Premium Insights
                        if subscriptionViewModel.isPremium {
                            NavigationLink(destination: PremiumInsightsView()) {
                                HStack {
                                    Label("Premium Insights", systemImage: "crown.fill")
                                        .foregroundColor(.orange)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                            .accessibilityLabel("Premium insights")
                            .accessibilityHint("Access advanced financial insights and analytics")
                        } else {
                            Button(action: {
                                subscriptionViewModel.showPaywall = true
                            }) {
                                HStack {
                                    Label("Premium Insights", systemImage: "crown.fill")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                            .accessibilityLabel("Premium insights (locked)")
                            .accessibilityHint("Requires premium subscription. Tap to upgrade.")
                        }
                        
                        Divider()
                            .padding(.leading)
                        
                        // Scenario Planning
                        if subscriptionViewModel.isPremium {
                            NavigationLink(destination: ScenarioPlanningView(context: viewContext)) {
                                HStack {
                                    Label("Scenario Planning", systemImage: "chart.line.uptrend.xyaxis")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                            .accessibilityLabel("Scenario planning")
                            .accessibilityHint("Plan different financial scenarios")
                        } else {
                            Button(action: {
                                subscriptionViewModel.showPaywall = true
                            }) {
                                HStack {
                                    Label("Scenario Planning", systemImage: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                            .accessibilityLabel("Scenario planning (locked)")
                            .accessibilityHint("Requires premium subscription. Tap to upgrade.")
                        }
                        
                        Divider()
                            .padding(.leading)
                        
                        // Upgrade or Manage Subscription
                        if subscriptionViewModel.isPremium {
                            Button(action: {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Label("Manage Subscription", systemImage: "gear")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                            .accessibilityLabel("Manage subscription")
                            .accessibilityHint("Opens App Store subscription management")
                        } else {
                            Button(action: {
                                subscriptionViewModel.showPaywall = true
                            }) {
                                HStack {
                                    Label("Upgrade to Premium", systemImage: "star.fill")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                            .accessibilityLabel("Upgrade to premium")
                            .accessibilityHint("Unlock premium features and insights")
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // App Settings Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Settings")
                        .headlineStyle()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                        .accessibleHeading(.h2)
                    
                    VStack(spacing: 0) {
                        NavigationLink(destination: CurrencySettingsView()) {
                            HStack {
                                Label("Currency", systemImage: "dollarsign.circle")
                                Spacer()
                                HStack(spacing: 4) {
                                    Text(CurrencyPreferenceManager.shared.preferredCurrency.rawValue)
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding()
                        }
                        .accessibilityLabel("Currency settings")
                        .accessibilityHint("Change your preferred currency")
                        
                        Divider()
                            .padding(.leading)
                        
                        NavigationLink(destination: PrivacyDashboardView(viewModel: createPrivacyDashboardViewModel(), container: container as! AppDIContainer)) {
                            HStack {
                                Label("Privacy", systemImage: "lock.shield")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("Privacy settings")
                        .accessibilityHint("Manage your privacy and data settings")
                        
                        Divider()
                            .padding(.leading)
                        
                        NavigationLink(destination: AnalyticsSettingsView()) {
                            HStack {
                                Label("Analytics", systemImage: "chart.bar")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("Analytics settings")
                        .accessibilityHint("Configure analytics and data collection")
                        
                        Divider()
                            .padding(.leading)
                        
                        NavigationLink(destination: BiometricSettingsView(container: container as! AppDIContainer)) {
                            HStack {
                                Label("Security", systemImage: "faceid")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("Security settings")
                        .accessibilityHint("Manage biometric authentication and security")
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Support Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Support")
                        .headlineStyle()
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                        .accessibleHeading(.h2)
                    
                    VStack(spacing: 0) {
                        NavigationLink(destination: HelpSupportView()) {
                            HStack {
                                Label("Help & Support", systemImage: "questionmark.circle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("Help and support")
                        .accessibilityHint("Get help and contact support")
                        
                        Divider()
                            .padding(.leading)
                        
                        NavigationLink(destination: AboutAppView()) {
                            HStack {
                                Label("About", systemImage: "info.circle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                        .accessibilityLabel("About the app")
                        .accessibilityHint("Learn about ClariFi and version information")
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Planning")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Planning view with budget management, premium features, app settings, and support")
            .onAppear {
                initializeViewModels()
                
                if appState.shouldPresentBudgetCreation {
                    navigationSelection = .createBudget
                    appState.shouldPresentBudgetCreation = false
                }
            }
            .onChange(of: appState.shouldPresentBudgetCreation) { _, shouldPresent in
                guard shouldPresent else { return }
                initializeViewModels()
                navigationSelection = .createBudget
                appState.shouldPresentBudgetCreation = false
            }
        }
        .sheet(isPresented: $subscriptionViewModel.showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeViewModels() {
        // Only initialize if not already created
        if budgetViewModel == nil {
            budgetViewModel = createBudgetViewModel()
        }
        if budgetCreationViewModel == nil {
            budgetCreationViewModel = createBudgetCreationViewModel()
        }
    }
    
    private func createBudgetViewModel() -> BudgetViewModel {
        // Check if dependencies are available in the container
        guard let transactionRepo: any TransactionRepository = container.resolveOptional(TransactionRepository.self),
              let budgetRepo: any BudgetRepository = container.resolveOptional(BudgetRepository.self),
              let budgetCategoryRepo: any BudgetCategoryRepository = container.resolveOptional(BudgetCategoryRepository.self) else {
            // Fallback for preview - create with mock repositories
            let mockTransactionRepo = CoreDataTransactionRepository(context: viewContext)
            let mockBudgetRepo = CoreDataBudgetRepository(context: viewContext)
            let mockBudgetCategoryRepo = CoreDataBudgetCategoryRepository(context: viewContext)
            
            let monitoringService = BudgetMonitoringService(
                budgetRepository: mockBudgetRepo,
                budgetCategoryRepository: mockBudgetCategoryRepo,
                transactionRepository: mockTransactionRepo,
                context: viewContext
            )
            
            return BudgetViewModel(
                budgetRepository: mockBudgetRepo,
                budgetCategoryRepository: mockBudgetCategoryRepo,
                transactionRepository: mockTransactionRepo,
                categoryMappingService: CategoryMappingService(),
                monitoringService: monitoringService,
                context: viewContext
            )
        }
        
        // Create BudgetMonitoringService with its dependencies
        let monitoringService = BudgetMonitoringService(
            budgetRepository: budgetRepo,
            budgetCategoryRepository: budgetCategoryRepo,
            transactionRepository: transactionRepo,
            context: viewContext
        )
        
        return BudgetViewModel(
            budgetRepository: budgetRepo,
            budgetCategoryRepository: budgetCategoryRepo,
            transactionRepository: transactionRepo,
            categoryMappingService: container.resolve(CategoryMappingServiceProtocol.self),
            monitoringService: monitoringService,
            context: viewContext
        )
    }
    
    private func createBudgetCreationViewModel() -> BudgetCreationViewModel {
        // Check if dependencies are available in the container
        guard let budgetRepo: any BudgetRepository = container.resolveOptional(BudgetRepository.self),
              let budgetCategoryRepo: any BudgetCategoryRepository = container.resolveOptional(BudgetCategoryRepository.self),
              let templateService = container.resolveOptional(BudgetTemplateService.self) else {
            // Fallback for preview - create with mock repositories
            let mockBudgetRepo = CoreDataBudgetRepository(context: viewContext)
            let mockBudgetCategoryRepo = CoreDataBudgetCategoryRepository(context: viewContext)
            let mockTemplateService = BudgetTemplateService()
            
            return BudgetCreationViewModel(
                budgetRepository: mockBudgetRepo,
                budgetCategoryRepository: mockBudgetCategoryRepo,
                templateService: mockTemplateService,
                context: viewContext
            )
        }
        
        return BudgetCreationViewModel(
            budgetRepository: budgetRepo,
            budgetCategoryRepository: budgetCategoryRepo,
            templateService: templateService,
            context: viewContext
        )
    }
    
    private func createPrivacyDashboardViewModel() -> PrivacyDashboardViewModel {
        // Check if PrivacyManager is available in the container
        guard let privacyManager: PrivacyManager = container.resolveOptional(PrivacyManager.self) else {
            // Fallback for preview - create with actual PrivacyManager
            let mockPrivacyManager = PrivacyManager(viewContext: viewContext)
            return PrivacyDashboardViewModel(privacyManager: mockPrivacyManager)
        }
        
        return PrivacyDashboardViewModel(privacyManager: privacyManager)
    }
}

private enum PlanningDestination: Hashable {
    case currentBudget
    case createBudget
}

// MARK: - Preview
#Preview {
    PlanningView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
        .environmentObject(SubscriptionViewModel())
}
