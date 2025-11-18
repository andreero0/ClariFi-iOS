//
//  DIContainer+Testing.swift
//  ClariFi iOSTests
//
//  Test helpers for dependency injection container
//  Provides test container setup with mock dependencies
//

import Foundation
import CoreData
@testable import ClariFi_iOS

extension AppDIContainer {
    /// Creates a test container with in-memory Core Data and mock dependencies
    /// Use this in tests instead of the production container
    static func createTestContainer(inMemoryContext: NSManagedObjectContext? = nil) -> DIContainer {
        let container = AppDIContainer()
        
        // Use provided context or create a new in-memory one
        let context: NSManagedObjectContext
        if let providedContext = inMemoryContext {
            context = providedContext
        } else {
            let persistenceController = PersistenceController(inMemory: true)
            context = persistenceController.container.viewContext
        }
        
        // Register Repositories (Singleton) with test context
        container.registerSingleton(TransactionRepository.self) { _ in
            CoreDataTransactionRepository(context: context)
        }
        container.registerSingleton(AccountRepository.self) { _ in
            CoreDataAccountRepository(context: context)
        }
        container.registerSingleton(BudgetRepository.self) { _ in
            CoreDataBudgetRepository(context: context)
        }
        container.registerSingleton(BudgetCategoryRepository.self) { _ in
            CoreDataBudgetCategoryRepository(context: context)
        }
        container.registerSingleton(StatementRepository.self) { _ in
            CoreDataStatementRepository(context: context)
        }
        container.registerSingleton(RecurringTransactionRepository.self) { _ in
            CoreDataRecurringTransactionRepository(context: context)
        }
        
        // Register Services (Singleton) - using mock for analytics, real for others
        container.registerSingleton(AnalyticsServiceProtocol.self) { _ in
            MockAnalyticsService()
        }
        container.registerSingleton(OCRService.self) { _ in
            VisionOCRService()
        }
        container.registerSingleton(TransactionParserService.self) { _ in
            SmartTransactionParser()
        }
        container.registerSingleton(CategoryMappingServiceProtocol.self) { _ in
            CategoryMappingService()
        }
        container.registerSingleton(CategoryService.self) { _ in
            CategoryService(context: context)
        }
        container.registerSingleton(RuleEngine.self) { _ in
            RuleEngine(context: context)
        }
        container.registerSingleton(BudgetTemplateService.self) { _ in
            BudgetTemplateService()
        }
        
        // Register Domain Services (Singleton)
        container.registerSingleton(InsightsEngineProtocol.self) { _ in
            InsightsEngine(context: context)
        }
        container.registerSingleton(BudgetMonitoringService.self) { c in
            BudgetMonitoringService(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        // Register ViewModels (Transient - new instance each time)
        container.register(BudgetViewModel.self) { c in
            BudgetViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                categoryMappingService: c.resolve(CategoryMappingServiceProtocol.self),
                monitoringService: c.resolve(BudgetMonitoringService.self),
                context: context
            )
        }
        container.register(InsightsViewModel.self) { c in
            InsightsViewModel(
                insightsEngine: c.resolve(InsightsEngineProtocol.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                budgetRepository: c.resolve(BudgetRepository.self),
                context: context
            )
        }
        container.register(StatementUploadViewModel.self) { c in
            StatementUploadViewModel(
                ocrService: c.resolve(OCRService.self),
                parserService: c.resolve(TransactionParserService.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                accountRepository: c.resolve(AccountRepository.self),
                context: context
            )
        }
        container.register(TransactionEntryViewModel.self) { c in
            TransactionEntryViewModel(
                transactionRepository: c.resolve(TransactionRepository.self),
                accountRepository: c.resolve(AccountRepository.self),
                categoryMappingService: c.resolve(CategoryMappingServiceProtocol.self),
                context: context,
                recurringService: nil
            )
        }
        container.register(BudgetCreationViewModel.self) { c in
            BudgetCreationViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                templateService: c.resolve(BudgetTemplateService.self),
                context: context
            )
        }
        container.register(BatchCategorizationViewModel.self) { c in
            BatchCategorizationViewModel(
                transactionRepository: c.resolve(TransactionRepository.self),
                categoryService: c.resolve(CategoryService.self),
                ruleEngine: c.resolve(RuleEngine.self),
                context: context
            )
        }
        container.register(CategorizationRulesViewModel.self) { c in
            CategorizationRulesViewModel(
                ruleEngine: c.resolve(RuleEngine.self),
                context: context
            )
        }
        container.register(PrivacyDashboardViewModel.self) { _ in
            PrivacyDashboardViewModel(
                privacyManager: PrivacyManager.shared,
                context: context
            )
        }
        
        return container
    }
}
