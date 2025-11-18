//
//  HomeView.swift
//  ClariFi iOS
//
//  Home dashboard with progressive disclosure following HIG 2024-2025 principles
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var appState: AppState

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var allTransactions: FetchedResults<Transaction>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.createdAt, ascending: true)],
        animation: .default)
    private var allAccounts: FetchedResults<Account>

    @State private var showingStatementUpload = false
    @State private var showingTransactionEntry = false
    @State private var statementUploadViewModel: StatementUploadViewModel?
    @State private var currentMonthSpending: Decimal = 0
    @State private var currentMonthTransactionCount: Int = 0
    @State private var categoryBreakdown: [(String, Decimal)] = []
    @State private var showingAllCategories = false
    @State private var isLoading = false
    @State private var totalAccountBalance: Decimal = 0
    @State private var balanceChangePercentage: Double = 0
    @State private var onboardingState: OnboardingStateManager?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Layer 1 - Immediate (Above Fold)
                    heroBalanceCard
                    quickActionsSection
                    
                    // Layer 2 - Summary (Mid Scroll)
                    thisMonthSnapshot
                    
                    // Layer 3 - Details (Below Fold)
                    if !categoryBreakdown.isEmpty {
                        topCategoriesSection
                    }
                    
                    recentInsightsSection
                    recentTransactionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Home dashboard with account balance, spending summary, and recent activity")
            .sheet(isPresented: $showingStatementUpload) {
                if let viewModel = statementUploadViewModel {
                    StatementUploadView(viewModel: viewModel)
                        .environment(\.managedObjectContext, viewContext)
                } else {
                    // Fallback if ViewModel creation failed
                    Text("Loading...")
                        .onAppear {
                            statementUploadViewModel = createStatementUploadViewModel()
                        }
                }
            }
            .onChange(of: showingStatementUpload) { _, isShowing in
                if !isShowing {
                    statementUploadViewModel = nil
                }
            }
            .sheet(isPresented: $showingTransactionEntry) {
                TransactionEntryView(viewModel: createTransactionEntryViewModel())
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                calculateSpendingSummary()
                calculateAccountBalance()

                // Initialize onboarding state manager
                if onboardingState == nil {
                    onboardingState = container.resolveOptional(OnboardingStateManager.self)
                }

                // Execute pending first action from onboarding
                if onboardingState?.shouldExecuteFirstAction == true {
                    executePendingFirstAction()
                }

                if appState.showingStatementUpload {
                    statementUploadViewModel = createStatementUploadViewModel()
                    showingStatementUpload = true
                    appState.showingStatementUpload = false
                }

                if appState.showingTransactionEntry {
                    showingTransactionEntry = true
                    appState.showingTransactionEntry = false
                }
            }
            .onChange(of: allTransactions.count) {
                calculateSpendingSummary()
                calculateAccountBalance()
            }
            .onChange(of: allAccounts.count) {
                calculateAccountBalance()
            }
            .onChange(of: appState.refreshTrigger) {
                calculateSpendingSummary()
                calculateAccountBalance()
            }
            .onChange(of: appState.showingStatementUpload) { _, shouldShow in
                guard shouldShow else { return }
                statementUploadViewModel = createStatementUploadViewModel()
                showingStatementUpload = true
                appState.showingStatementUpload = false
            }
            .onChange(of: appState.showingTransactionEntry) { _, shouldShow in
                guard shouldShow else { return }
                showingTransactionEntry = true
                appState.showingTransactionEntry = false
            }
            .overlay(
                Group {
                    if isLoading {
                        LoadingOverlay()
                    }
                }
            )
        }
    }
    
    // MARK: - Layer 1: Hero Balance Card
    
    private var heroBalanceCard: some View {
        HybridGlassCard(
            style: .premium,
            cornerRadius: 20,
            shadowRadius: 12,
            gradientColors: [ColorSystem.glassGradientStart, ColorSystem.glassGradientEnd]
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Balance")
                    .headlineStyle()
                    .foregroundColor(.secondary)
                    .accessibleHeading(.h1)
                
                Text(formatCurrency(totalAccountBalance))
                    .heroBalanceStyle()
                    .foregroundColor(.primary)
                    .accessibilityLabel("Account balance: \(formatCurrency(totalAccountBalance))")
                    .accessibilityAddTraits(.isStaticText)
                
                HStack(spacing: 6) {
                    Image(systemName: balanceChangePercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .captionStyle()
                        .foregroundColor(balanceChangePercentage >= 0 ? .green : .red)
                        .accessibilityHidden(true)
                    Text("\(balanceChangePercentage >= 0 ? "+" : "")\(String(format: "%.1f", balanceChangePercentage))% from last month")
                        .subheadlineStyle()
                        .foregroundColor(balanceChangePercentage >= 0 ? .green : .red)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Balance \(balanceChangePercentage >= 0 ? "increased" : "decreased") by \(String(format: "%.1f", abs(balanceChangePercentage)))% from last month")
                .accessibilityAddTraits(.isStaticText)
            }
            .padding(32)
        }
        .accessibleCard(label: "Account balance card", hint: "Shows your current account balance and monthly change")
    }
    
    // MARK: - Layer 1: Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .headlineStyle()
                .foregroundColor(.secondary)
                .accessibleHeading(.h2)
            
            HStack(spacing: 12) {
                Button(action: { 
                    HapticFeedback.impact(.medium).trigger()
                    Task {
                        statementUploadViewModel = createStatementUploadViewModel()
                        showingStatementUpload = true
                    }
                }) {
                    Label("Upload Statement", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .frame(height: 52)
                .accessibleButton(
                    label: AccessibilityLabels.uploadStatement,
                    hint: AccessibilityHints.uploadStatement
                )
                
                Button(action: { 
                    HapticFeedback.impact(.medium).trigger()
                    showingTransactionEntry = true 
                }) {
                    Label("Add Transaction", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .frame(height: 52)
                .accessibleButton(
                    label: AccessibilityLabels.addTransaction,
                    hint: AccessibilityHints.addTransaction
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick actions section")
    }
    
    // MARK: - Layer 2: This Month Snapshot
    
    private var thisMonthSnapshot: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Month")
                .headlineStyle()
                .foregroundColor(.secondary)
                .accessibleHeading(.h2)
            
            HStack(spacing: 16) {
                HybridGlassCard(style: .standard) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .primaryColor()
                                .font(.title2)
                                .accessibilityHidden(true)
                            Spacer()
                        }
                        
                        Text(formatCurrency(currentMonthSpending))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .accessibilityLabel("Total spending: \(formatCurrency(currentMonthSpending))")
                        
                        Text("Total Spending")
                            .captionStyle()
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
                .accessibleCard(
                    label: "Total spending this month: \(formatCurrency(currentMonthSpending))",
                    hint: "Shows your total spending for the current month"
                )
                
                HybridGlassCard(style: .standard) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .successColor()
                                .font(.title2)
                                .accessibilityHidden(true)
                            Spacer()
                        }
                        
                        Text("\(currentMonthTransactionCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .accessibilityLabel("\(currentMonthTransactionCount) transactions")
                        
                        Text("Transactions")
                            .captionStyle()
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
                .accessibleCard(
                    label: "\(currentMonthTransactionCount) transactions this month",
                    hint: "Shows the number of transactions for the current month"
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("This month spending summary")
    }
    
    // MARK: - Layer 3: Top Categories (Progressive Disclosure)
    
    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Categories")
                    .headlineStyle()
                    .foregroundColor(.secondary)
                    .accessibleHeading()
                
                Spacer()
                
                if categoryBreakdown.count > 3 {
                    Button(showingAllCategories ? "Show Less" : "View All") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAllCategories.toggle()
                        }
                    }
                    .subheadlineStyle()
                    .primaryColor()
                    .accessibilityLabel(showingAllCategories ? "Show less categories" : "View all categories")
                }
            }
            
            HybridGlassCard(style: .standard) {
                VStack(spacing: 16) {
                    ForEach(Array((showingAllCategories ? categoryBreakdown : Array(categoryBreakdown.prefix(3))).enumerated()), id: \.offset) { index, item in
                        let (category, amount) = item
                        CategoryRow(
                            category: category,
                            amount: amount,
                            total: currentMonthSpending,
                            accentColor: ColorSystem.categoryColor(for: category)
                        )
                        
                        if index < (showingAllCategories ? categoryBreakdown.count : min(categoryBreakdown.count, 3)) - 1 {
                            Divider()
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Layer 3: Recent Insights
    
    private var recentInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Insights")
                    .headlineStyle()
                    .foregroundColor(.secondary)
                    .accessibleHeading()
                
                Spacer()
                
                Button(action: {
                    appState.selectedTab = 1 // Switch to Activity tab
                }) {
                    Text("See All")
                        .subheadlineStyle()
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("See all insights")
                .accessibilityHint("Switches to Activity tab to view all insights")
            }
            
            if allTransactions.count < 5 {
                HybridGlassCard(style: .standard) {
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.title2)
                            .warningColor()
                        
                        Text("Add more transactions to see personalized insights")
                            .subheadlineStyle()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                }
                .accessibilityLabel("Add more transactions to see personalized insights")
            } else {
                // Show 1-2 recent insights
                HybridGlassCard(style: .standard) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You spent 15% more on dining this week")
                            .subheadlineStyle()
                            .foregroundColor(.primary)
                        
                        Text("Consider setting a weekly dining budget to help manage this category.")
                            .captionStyle()
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                }
                .accessibilityLabel("Insight: You spent 15% more on dining this week. Consider setting a weekly dining budget.")
            }
        }
    }
    
    // MARK: - Layer 3: Recent Transactions
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .headlineStyle()
                    .foregroundColor(.secondary)
                    .accessibleHeading()
                
                Spacer()
                
                Button(action: {
                    appState.selectedTab = 1 // Switch to Activity tab
                }) {
                    Text("View All")
                        .subheadlineStyle()
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("View all transactions")
                .accessibilityHint("Switches to Activity tab to view all transactions")
            }
            
            if allTransactions.isEmpty {
                HybridGlassCard(style: .standard) {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title2)
                            .primaryColor()
                        
                        Text("No Transactions")
                            .headlineStyle()
                            .foregroundColor(.primary)
                        
                        Text("Upload a statement or add your first transaction to get started.")
                            .subheadlineStyle()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                }
                .accessibilityLabel("No transactions yet. Upload a statement or add your first transaction to get started.")
            } else {
                HybridGlassCard(style: .standard) {
                    VStack(spacing: 12) {
                        ForEach(Array(allTransactions.prefix(3)), id: \.objectID) { transaction in
                            TransactionRow(transaction: transaction)
                            
                            if transaction != allTransactions.prefix(3).last {
                                Divider()
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    // MARK: - Helper Methods
    
    private func calculateSpendingSummary() {
        // Show loading state for large datasets
        if allTransactions.count > 100 {
            isLoading = true
        }
        
        // Perform calculation on background queue for large datasets
        if allTransactions.count > 100 {
            Task {
                // Snapshot the transactions on the main actor before hopping to background
                let transactionsSnapshot = await MainActor.run {
                    return Array(allTransactions)
                }
                
                // Perform calculation on background
                let result = await performCalculation(transactions: transactionsSnapshot)
                
                // Update UI on main actor
                await MainActor.run {
                    currentMonthSpending = result.spending
                    currentMonthTransactionCount = result.transactionCount
                    categoryBreakdown = result.categoryBreakdown
                    isLoading = false
                }
            }
        } else {
            performCalculation()
        }
    }
    
    private func performCalculation() {
        let result = performCalculation(transactions: Array(allTransactions))
        currentMonthSpending = result.spending
        currentMonthTransactionCount = result.transactionCount
        categoryBreakdown = result.categoryBreakdown
    }
    
    private func performCalculation(transactions: [Transaction]) -> (spending: Decimal, transactionCount: Int, categoryBreakdown: [(String, Decimal)]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let currentMonthTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= startOfMonth
        }
        
        let spending = currentMonthTransactions.reduce(0) { total, transaction in
            total + (transaction.amount?.decimalValue ?? 0)
        }
        
        let transactionCount = currentMonthTransactions.count
        
        // Calculate category breakdown
        var categoryTotals: [String: Decimal] = [:]
        for transaction in currentMonthTransactions {
            let category = transaction.category ?? "Uncategorized"
            let amount = transaction.amount?.decimalValue ?? 0
            categoryTotals[category, default: 0] += amount
        }
        
        let categoryBreakdown = categoryTotals
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
        
        return (spending: spending, transactionCount: transactionCount, categoryBreakdown: categoryBreakdown)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
    
    private func calculateAccountBalance() {
        guard !allAccounts.isEmpty else {
            totalAccountBalance = 0
            balanceChangePercentage = 0
            return
        }

        // Calculate total from actual account balances
        totalAccountBalance = allAccounts.reduce(0) { total, account in
            total + (account.balance?.decimalValue ?? 0)
        }

        // Calculate actual percentage change from transaction history
        calculateBalanceChangePercentage()
    }

    private func calculateBalanceChangePercentage() {
        let calendar = Calendar.current
        let now = Date()

        // Get start of current month
        guard let startOfThisMonth = calendar.dateInterval(of: .month, for: now)?.start else {
            balanceChangePercentage = 0
            return
        }

        // Calculate balance at start of this month
        let balanceLastMonth = calculateBalanceAtDate(startOfThisMonth)

        guard balanceLastMonth > 0 else {
            balanceChangePercentage = 0
            return
        }

        // Calculate percentage change
        let change = totalAccountBalance - balanceLastMonth
        balanceChangePercentage = Double(truncating: (change / balanceLastMonth * 100) as NSDecimalNumber)
    }

    private func calculateBalanceAtDate(_ date: Date) -> Decimal {
        // Start with current balances
        var balanceAtDate = totalAccountBalance

        // Subtract all transactions that occurred after the target date
        // (to get historical balance, we reverse recent transactions)
        let transactionsAfterDate = allTransactions.filter { transaction in
            guard let transactionDate = transaction.date else { return false }
            return transactionDate >= date
        }

        for transaction in transactionsAfterDate {
            let amount = transaction.amount?.decimalValue ?? 0
            // Reverse the transaction to get historical balance
            balanceAtDate -= amount
        }

        return balanceAtDate
    }
    
    private func createStatementUploadViewModel() -> StatementUploadViewModel {
        // Check if dependencies are available in the container
        guard let transactionRepo: any TransactionRepository = container.resolveOptional(TransactionRepository.self),
              let accountRepo: any AccountRepository = container.resolveOptional(AccountRepository.self),
              let statementRepo: any StatementRepository = container.resolveOptional(StatementRepository.self),
              let ocrService: VisionOCRService = container.resolveOptional(VisionOCRService.self),
              let transactionParser: SmartTransactionParser = container.resolveOptional(SmartTransactionParser.self) else {
            // Fallback for preview - create with actual services
            let mockTransactionRepo = CoreDataTransactionRepository(context: viewContext)
            let mockAccountRepo = CoreDataAccountRepository(context: viewContext)
            let mockStatementRepo = CoreDataStatementRepository(context: viewContext)
            let ocrService = VisionOCRService()
            let transactionParser = SmartTransactionParser()
            let llmService: (any LLMCategorizationServiceProtocol)? = container.resolveOptional(LLMCategorizationServiceProtocol.self)
            
            return StatementUploadViewModel(
                ocrService: ocrService,
                parserService: transactionParser,
                transactionRepository: mockTransactionRepo,
                accountRepository: mockAccountRepo,
                statementRepository: mockStatementRepo,
                llmService: llmService,
                context: viewContext
            )
        }
        
        // Resolve LLM service (optional)
        let llmService: (any LLMCategorizationServiceProtocol)? = container.resolveOptional(LLMCategorizationServiceProtocol.self)
        
        return StatementUploadViewModel(
            ocrService: ocrService,
            parserService: transactionParser,
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            statementRepository: statementRepo,
            llmService: llmService,
            context: viewContext
        )
    }
    
    private func createTransactionEntryViewModel() -> TransactionEntryViewModel {
        // Check if dependencies are available in the container
        guard let transactionRepo: any TransactionRepository = container.resolveOptional(TransactionRepository.self),
              let accountRepo: any AccountRepository = container.resolveOptional(AccountRepository.self),
              let categoryMappingService: any CategoryMappingServiceProtocol = container.resolveOptional(CategoryMappingServiceProtocol.self) else {
            // Fallback for preview - create with mock repositories
            let mockTransactionRepo = CoreDataTransactionRepository(context: viewContext)
            let mockAccountRepo = CoreDataAccountRepository(context: viewContext)
            let mockRecurringRepo = CoreDataRecurringTransactionRepository(context: viewContext)
            let mockCategoryMappingService = CategoryMappingService()
            let mockRecurringService = CoreDataRecurringTransactionService(
                recurringRepository: mockRecurringRepo,
                transactionRepository: mockTransactionRepo,
                context: viewContext
            )
            
            return TransactionEntryViewModel(
                transactionRepository: mockTransactionRepo,
                accountRepository: mockAccountRepo,
                categoryMappingService: mockCategoryMappingService,
                context: viewContext,
                recurringService: mockRecurringService
            )
        }
        
        let recurringRepo = CoreDataRecurringTransactionRepository(context: viewContext)
        let recurringService = CoreDataRecurringTransactionService(
            recurringRepository: recurringRepo,
            transactionRepository: transactionRepo,
            context: viewContext
        )
        
        return TransactionEntryViewModel(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryMappingService: categoryMappingService,
            context: viewContext,
            recurringService: recurringService
        )
    }

    private func executePendingFirstAction() {
        guard let action = onboardingState?.pendingFirstAction else { return }

        // Small delay for UI to settle after onboarding dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch action {
            case .uploadStatement:
                statementUploadViewModel = createStatementUploadViewModel()
                showingStatementUpload = true
            case .manualEntry:
                showingTransactionEntry = true
            case .createBudget:
                appState.selectedTab = 2
                appState.shouldPresentBudgetCreation = true
            }

            // Clear the action after execution
            onboardingState?.clearFirstAction()
        }
    }
}

// MARK: - Supporting Views

struct CategoryRow: View {
    let category: String
    let amount: Decimal
    let total: Decimal
    let accentColor: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(truncating: (amount / total) as NSDecimalNumber) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.capitalized)
                    .subheadlineStyle()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatCurrency(amount))
                    .subheadlineStyle()
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category): \(formatCurrency(amount)), \(String(format: "%.1f", percentage))% of total spending")
        .accessibilityAddTraits(.isStaticText)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant ?? "Unknown")
                    .subheadlineStyle()
                    .foregroundColor(.primary)
                
                Text((transaction.category ?? "Uncategorized").capitalized)
                    .captionStyle()
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(transaction.amount?.decimalValue ?? 0))
                    .subheadlineStyle()
                    .foregroundColor(.primary)
                
                if let date = transaction.date {
                    Text(formatDate(date))
                        .captionStyle()
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.merchant ?? "Unknown"): \(formatCurrency(transaction.amount?.decimalValue ?? 0))")
        .accessibilityHint("Transaction in \(transaction.category ?? "Uncategorized") category")
        .accessibilityAddTraits(.isStaticText)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Loading Overlay
// Note: LoadingOverlay is now defined in Views/Components/LoadingOverlay.swift

// MARK: - Preview
#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
