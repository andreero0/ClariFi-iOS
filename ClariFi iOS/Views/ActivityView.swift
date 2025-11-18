//
//  ActivityView.swift
//  ClariFi iOS
//
//  Consolidated view for Transactions and Insights with segmented control
//

import SwiftUI

struct ActivityView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("View", selection: $selectedSegment) {
                    Text("Transactions").tag(0)
                    Text("Insights").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .accessibilityLabel("Activity view selector")
                .accessibilityHint("Switch between transactions and insights views")
                
                // Content based on selection - Lazy loading for performance
                Group {
                    if selectedSegment == 0 {
                        TransactionsListView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(appState)
                            .accessibilityLabel("Transactions list")
                            .id("transactions") // Ensures proper view recycling
                    } else {
                        InsightsView(viewModel: createInsightsViewModel())
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(appState)
                            .accessibilityLabel("Insights view")
                            .id("insights") // Ensures proper view recycling
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSegment)
            }
            .navigationTitle("Activity")
            .accessibilityElement(children: .contain)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createInsightsViewModel() -> InsightsViewModel {
        // Check if dependencies are available in the container
        guard let transactionRepo: any TransactionRepository = container.resolveOptional(TransactionRepository.self),
              let budgetRepo: any BudgetRepository = container.resolveOptional(BudgetRepository.self),
              let insightsEngine: any InsightsEngineProtocol = container.resolveOptional(InsightsEngineProtocol.self) else {
            // Fallback for preview - create with mock repositories
            let mockTransactionRepo = CoreDataTransactionRepository(context: viewContext)
            let mockBudgetRepo = CoreDataBudgetRepository(context: viewContext)
            let mockInsightsEngine = InsightsEngine(context: viewContext)
            
            return InsightsViewModel(
                insightsEngine: mockInsightsEngine,
                transactionRepository: mockTransactionRepo,
                budgetRepository: mockBudgetRepo,
                context: viewContext
            )
        }
        
        return InsightsViewModel(
            insightsEngine: insightsEngine,
            transactionRepository: transactionRepo,
            budgetRepository: budgetRepo,
            context: viewContext
        )
    }
}

// MARK: - Preview
#Preview {
    ActivityView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
