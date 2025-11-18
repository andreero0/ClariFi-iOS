//
//  TransactionsListView.swift
//  ClariFi iOS
//
//  Transaction list with search, filtering, and sorting capabilities
//

import SwiftUI
import CoreData

struct TransactionsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var allTransactions: FetchedResults<Transaction>
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var sortOption: SortOption = .dateDescending
    @State private var showingFilters = false
    @State private var showingTransactionEntry = false
    @State private var dateFilter: DateFilter = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter chips
                if selectedCategory != nil || dateFilter != .all {
                    filterChipsBar
                }
                
                // Transaction list
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionList
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        sortMenu
                        Divider()
                        filterMenu
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTransactionEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTransactionEntry) {
                TransactionEntryView(viewModel: createTransactionEntryViewModel())
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Filter Chips Bar
    
    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = selectedCategory {
                    FilterChip(
                        title: category,
                        icon: "tag.fill"
                    ) {
                        selectedCategory = nil
                    }
                }
                
                if dateFilter != .all {
                    FilterChip(
                        title: dateFilter.displayName,
                        icon: "calendar"
                    ) {
                        dateFilter = .all
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Transaction List
    
    private var transactionList: some View {
        List {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(formatSectionDate(date))) {
                    ForEach(groupedTransactions[date] ?? []) { transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            TransactionRowView(transaction: transaction)
                        }
                    }
                    .onDelete { indexSet in
                        deleteTransactions(at: indexSet, in: groupedTransactions[date] ?? [])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Transactions" : "No Results")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "Add transactions to get started" : "Try adjusting your search or filters")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                Button("Add Transaction") {
                    showingTransactionEntry = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sort Menu
    
    private var sortMenu: some View {
        Group {
            Button {
                sortOption = .dateDescending
            } label: {
                Label("Date (Newest)", systemImage: sortOption == .dateDescending ? "checkmark" : "")
            }
            
            Button {
                sortOption = .dateAscending
            } label: {
                Label("Date (Oldest)", systemImage: sortOption == .dateAscending ? "checkmark" : "")
            }
            
            Button {
                sortOption = .amountDescending
            } label: {
                Label("Amount (High to Low)", systemImage: sortOption == .amountDescending ? "checkmark" : "")
            }
            
            Button {
                sortOption = .amountAscending
            } label: {
                Label("Amount (Low to High)", systemImage: sortOption == .amountAscending ? "checkmark" : "")
            }
            
            Button {
                sortOption = .merchant
            } label: {
                Label("Merchant (A-Z)", systemImage: sortOption == .merchant ? "checkmark" : "")
            }
        }
    }
    
    // MARK: - Filter Menu
    
    private var filterMenu: some View {
        Group {
            Menu("Date Range") {
                Button("All Time") { dateFilter = .all }
                Button("This Month") { dateFilter = .thisMonth }
                Button("Last Month") { dateFilter = .lastMonth }
                Button("Last 3 Months") { dateFilter = .last3Months }
                Button("This Year") { dateFilter = .thisYear }
            }
            
            Menu("Category") {
                Button("All Categories") { selectedCategory = nil }
                Divider()
                ForEach(availableCategories, id: \.self) { category in
                    Button(category) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTransactions: [Transaction] {
        var transactions = Array(allTransactions)
        
        // Apply search filter
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                let merchant = transaction.merchant?.lowercased() ?? ""
                let category = transaction.category?.lowercased() ?? ""
                let amount = formatCurrency(transaction.amount?.decimalValue ?? 0).lowercased()
                let search = searchText.lowercased()
                
                return merchant.contains(search) || category.contains(search) || amount.contains(search)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            transactions = transactions.filter { $0.category == category }
        }
        
        // Apply date filter
        transactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return dateFilter.includes(date)
        }
        
        // Apply sorting
        transactions.sort { lhs, rhs in
            switch sortOption {
            case .dateDescending:
                return (lhs.date ?? Date.distantPast) > (rhs.date ?? Date.distantPast)
            case .dateAscending:
                return (lhs.date ?? Date.distantPast) < (rhs.date ?? Date.distantPast)
            case .amountDescending:
                return (lhs.amount?.decimalValue ?? 0) > (rhs.amount?.decimalValue ?? 0)
            case .amountAscending:
                return (lhs.amount?.decimalValue ?? 0) < (rhs.amount?.decimalValue ?? 0)
            case .merchant:
                return (lhs.merchant ?? "") < (rhs.merchant ?? "")
            }
        }
        
        return transactions
    }
    
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: filteredTransactions) { transaction in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: transaction.date ?? Date())
            return calendar.date(from: components) ?? Date()
        }
    }
    
    private var availableCategories: [String] {
        let categories = Set(allTransactions.compactMap { $0.category })
        return Array(categories).sorted()
    }
    
    // MARK: - Helper Methods
    
    private func deleteTransactions(at offsets: IndexSet, in transactions: [Transaction]) {
        withAnimation {
            offsets.map { transactions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
                appState.refreshData()
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return CurrencyPreferenceManager.shared.formatWithSymbol(amount)
    }
    
    // MARK: - Helper Methods
    
    private func createTransactionEntryViewModel() -> TransactionEntryViewModel {
        // Check if dependencies are available in the container
        guard let transactionRepo: any TransactionRepository = container.resolveOptional(TransactionRepository.self),
              let accountRepo: any AccountRepository = container.resolveOptional(AccountRepository.self) else {
            // Fallback for preview - create with mock repositories
            let mockTransactionRepo = CoreDataTransactionRepository(context: viewContext)
            let mockAccountRepo = CoreDataAccountRepository(context: viewContext)
            let mockRecurringRepo = CoreDataRecurringTransactionRepository(context: viewContext)
            let mockRecurringService = CoreDataRecurringTransactionService(
                recurringRepository: mockRecurringRepo,
                transactionRepository: mockTransactionRepo,
                context: viewContext
            )
            
            return TransactionEntryViewModel(
                transactionRepository: mockTransactionRepo,
                accountRepository: mockAccountRepo,
                categoryMappingService: CategoryMappingService(),
                context: viewContext,
                recurringService: mockRecurringService
            )
        }
        
        let recurringTransactionRepository: any RecurringTransactionRepository = container.resolveOptional(RecurringTransactionRepository.self) ?? CoreDataRecurringTransactionRepository(context: viewContext)
        let recurringService = CoreDataRecurringTransactionService(
            recurringRepository: recurringTransactionRepository,
            transactionRepository: transactionRepo,
            context: viewContext
        )
        
        return TransactionEntryViewModel(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryMappingService: container.resolve(CategoryMappingServiceProtocol.self),
            context: viewContext,
            recurringService: recurringService
        )
    }
}

// MARK: - Supporting Types

enum SortOption {
    case dateDescending
    case dateAscending
    case amountDescending
    case amountAscending
    case merchant
}

enum DateFilter {
    case all
    case thisMonth
    case lastMonth
    case last3Months
    case thisYear
    
    var displayName: String {
        switch self {
        case .all: return "All Time"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last3Months: return "Last 3 Months"
        case .thisYear: return "This Year"
        }
    }
    
    func includes(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return true
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: lastMonth, toGranularity: .month)
        case .last3Months:
            guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else { return false }
            return date >= threeMonthsAgo
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationView {
        TransactionsListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppState())
    }
}
