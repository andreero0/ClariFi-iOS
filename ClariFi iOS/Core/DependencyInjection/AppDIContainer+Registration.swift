//
//  AppDIContainer+Registration.swift
//  ClariFi iOS
//
//  Created by Kiro
//  DI Container registration for production and test environments
//

import Foundation
import CoreData
import Supabase

extension AppDIContainer {
    
    // MARK: - Production Container
    
    /// Creates and configures the production DI container with all dependencies
    /// - Returns: Fully configured DIContainer ready for use
    nonisolated static func createProductionContainer() -> DIContainer {
        let container = AppDIContainer()
        
        // Get Core Data context from shared persistence controller
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext
        
        // Create background context provider
        let backgroundContextProvider = BackgroundContextProvider(persistentContainer: persistenceController.container)
        
        // MARK: - Register Repositories (Singleton)
        // Repositories are singletons because they manage Core Data access
        // and should maintain consistent state throughout the app lifecycle
        
        container.registerSingleton((any TransactionRepository).self) { _ in
            CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any AccountRepository).self) { _ in
            CoreDataAccountRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any BudgetRepository).self) { _ in
            CoreDataBudgetRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any BudgetCategoryRepository).self) { _ in
            CoreDataBudgetCategoryRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any StatementRepository).self) { _ in
            CoreDataStatementRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any RecurringTransactionRepository).self) { _ in
            CoreDataRecurringTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        // MARK: - Register Core Services (Singleton)
        // Core services are singletons to maintain consistent state
        // and avoid expensive re-initialization
        
        container.registerSingleton((any AnalyticsServiceProtocol).self) { _ in
            PostHogAnalyticsService()
        }
        
        container.registerSingleton((any OCRService).self) { _ in
            VisionOCRService()
        }
        
        container.registerSingleton(VisionOCRService.self) { _ in
            VisionOCRService()
        }
        
        container.registerSingleton((any TransactionParserService).self) { _ in
            SmartTransactionParser()
        }
        
        container.registerSingleton(SmartTransactionParser.self) { _ in
            SmartTransactionParser()
        }
        
        container.registerSingleton(BudgetTemplateService.self) { _ in
            BudgetTemplateService()
        }
        
        container.registerSingleton((any CategoryMappingServiceProtocol).self) { _ in
            CategoryMappingService()
        }
        
        container.registerSingleton(EncryptionService.self) { _ in
            EncryptionService.shared
        }
        
        container.registerSingleton(BiometricAuthService.self) { _ in
            BiometricAuthService.shared
        }

        container.registerSingleton(SecurityAuditService.self) { c in
            SecurityAuditService(
                encryptionService: c.resolve(EncryptionService.self),
                secureFileManager: c.resolve(SecureFileManager.self)
            )
        }

        // MARK: - Register Authentication Services (Singleton)
        // Authentication services for user registration, login, and session management

        container.registerSingleton(SupabaseClient.self) { _ in
            let config = SupabaseConfiguration.shared
            return SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
        }

        container.registerSingleton(SessionManager.self) { c in
            MainActor.assumeIsolated {
                SessionManager(supabase: c.resolve(SupabaseClient.self))
            }
        }

        container.registerSingleton((any AuthenticationServiceProtocol).self) { c in
            MainActor.assumeIsolated {
                AuthenticationService(
                    supabase: c.resolve(SupabaseClient.self),
                    context: context,
                    sessionManager: c.resolve(SessionManager.self)
                )
            }
        }
        
        container.registerSingleton(InsightNotificationService.self) { _ in
            InsightNotificationService.shared
        }
        
        container.registerSingleton(SecureFileManager.self) { _ in
            SecureFileManager.shared
        }
        
        // MARK: - Register Domain Services (Singleton)
        // Domain services with dependencies resolved from container
        
        // MARK: - Register LLM Services (Singleton)
        // LLM services for privacy-first on-device categorization
        
        container.registerSingleton(AppleFoundationModelManager.self) { _ in
            MainActor.assumeIsolated {
                AppleFoundationModelManager()
            }
        }
        
        container.registerSingleton((any LLMCategorizationServiceProtocol).self) { c in
            // Create a temporary CategoryService for fallback (without LLM to avoid circular dependency)
            let fallbackService = CategoryService(
                context: context,
                backgroundContextProvider: backgroundContextProvider,
                transactionRepository: c.resolve(TransactionRepository.self),
                llmService: nil
            )
            
            return AppleLLMCategorizationService(
                modelManager: c.resolve(AppleFoundationModelManager.self),
                fallbackService: fallbackService,
                categoryMappingService: c.resolve(CategoryMappingServiceProtocol.self)
            )
        }
        
        container.registerSingleton((any CategoryServiceProtocol).self) { c in
            CategoryService(
                context: context,
                backgroundContextProvider: backgroundContextProvider,
                transactionRepository: c.resolve(TransactionRepository.self),
                llmService: c.resolve(LLMCategorizationServiceProtocol.self)
            )
        }
        
        container.registerSingleton((any RuleEngineProtocol).self) { _ in
            RuleEngine(context: context)
        }
        
        container.registerSingleton((any InsightsEngineProtocol).self) { _ in
            InsightsEngine(context: context)
        }
        
        container.registerSingleton((any BudgetMonitoringServiceProtocol).self) { c in
            BudgetMonitoringService(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        container.registerSingleton(CashflowForecastingService.self) { _ in
            CashflowForecastingService(
                context: context,
                backgroundContextProvider: backgroundContextProvider
            )
        }
        
        container.registerSingleton(RecurringTransactionService.self) { c in
            CoreDataRecurringTransactionService(
                recurringRepository: c.resolve(RecurringTransactionRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        container.registerSingleton((any SubscriptionServiceProtocol).self) { _ in
            SubscriptionService()
        }
        
        container.registerSingleton(ScenarioPlanningService.self) { _ in
            ScenarioPlanningService(
                context: context,
                backgroundContextProvider: backgroundContextProvider
            )
        }
        
        // MARK: - Register Privacy Manager
        container.registerSingleton(PrivacyManager.self) { _ in
            PrivacyManager(viewContext: context)
        }
        
        // MARK: - Register ViewModels (Transient)
        // ViewModels are registered as transient (new instance each time)
        // Some ViewModels that require complex dependency injection are registered here
        
        container.register(BudgetCreationViewModel.self) { c in
            BudgetCreationViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                templateService: c.resolve(BudgetTemplateService.self),
                context: context
            )
        }
        
        return container
    }
    
    // MARK: - Preview Container
    
    /// Creates a preview DI container with preview dependencies
    /// - Returns: DIContainer configured for SwiftUI previews
    @MainActor
    static func createPreviewContainer() -> DIContainer {
        let container = AppDIContainer()
        
        // Get Core Data context from preview persistence controller
        let context = PersistenceController.preview.container.viewContext
        
        // Create background context provider for preview
        let backgroundContextProvider = BackgroundContextProvider(persistentContainer: PersistenceController.preview.container)
        
        // MARK: - Register Repositories (Singleton)
        container.registerSingleton((any TransactionRepository).self) { _ in
            CoreDataTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any AccountRepository).self) { _ in
            CoreDataAccountRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any BudgetRepository).self) { _ in
            CoreDataBudgetRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any BudgetCategoryRepository).self) { _ in
            CoreDataBudgetCategoryRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any StatementRepository).self) { _ in
            CoreDataStatementRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        container.registerSingleton((any RecurringTransactionRepository).self) { _ in
            CoreDataRecurringTransactionRepository(context: context, backgroundContextProvider: backgroundContextProvider)
        }
        
        // MARK: - Register Core Services (Singleton)
        container.registerSingleton((any AnalyticsServiceProtocol).self) { _ in
            PostHogAnalyticsService()
        }
        
        container.registerSingleton((any OCRService).self) { _ in
            VisionOCRService()
        }
        
        container.registerSingleton(VisionOCRService.self) { _ in
            VisionOCRService()
        }
        
        container.registerSingleton((any TransactionParserService).self) { _ in
            SmartTransactionParser()
        }
        
        container.registerSingleton(SmartTransactionParser.self) { _ in
            SmartTransactionParser()
        }
        
        container.registerSingleton(BudgetTemplateService.self) { _ in
            BudgetTemplateService()
        }
        
        container.registerSingleton((any CategoryMappingServiceProtocol).self) { _ in
            CategoryMappingService()
        }
        
        container.registerSingleton(EncryptionService.self) { _ in
            EncryptionService.shared
        }
        
        container.registerSingleton(BiometricAuthService.self) { _ in
            BiometricAuthService.shared
        }

        container.registerSingleton(SecureFileManager.self) { _ in
            SecureFileManager.shared
        }

        container.registerSingleton(SecurityAuditService.self) { c in
            SecurityAuditService(
                encryptionService: c.resolve(EncryptionService.self),
                secureFileManager: c.resolve(SecureFileManager.self)
            )
        }

        // MARK: - Register Authentication Services (Singleton)
        // Authentication services for user registration, login, and session management

        container.registerSingleton(SupabaseClient.self) { _ in
            let config = SupabaseConfiguration.shared
            return SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
        }

        container.registerSingleton(SessionManager.self) { c in
            MainActor.assumeIsolated {
                SessionManager(supabase: c.resolve(SupabaseClient.self))
            }
        }

        container.registerSingleton((any AuthenticationServiceProtocol).self) { c in
            MainActor.assumeIsolated {
                AuthenticationService(
                    supabase: c.resolve(SupabaseClient.self),
                    context: context,
                    sessionManager: c.resolve(SessionManager.self)
                )
            }
        }

        // MARK: - Register Domain Services (Singleton)
        
        // MARK: - Register LLM Services (Singleton)
        container.registerSingleton(AppleFoundationModelManager.self) { _ in
            MainActor.assumeIsolated {
                AppleFoundationModelManager()
            }
        }
        
        container.registerSingleton((any LLMCategorizationServiceProtocol).self) { c in
            let fallbackService = CategoryService(
                context: context,
                backgroundContextProvider: backgroundContextProvider,
                transactionRepository: c.resolve(TransactionRepository.self),
                llmService: nil
            )
            
            return AppleLLMCategorizationService(
                modelManager: c.resolve(AppleFoundationModelManager.self),
                fallbackService: fallbackService,
                categoryMappingService: c.resolve(CategoryMappingServiceProtocol.self)
            )
        }
        
        container.registerSingleton((any CategoryServiceProtocol).self) { c in
            CategoryService(
                context: context,
                backgroundContextProvider: backgroundContextProvider,
                transactionRepository: c.resolve(TransactionRepository.self),
                llmService: c.resolve(LLMCategorizationServiceProtocol.self)
            )
        }
        
        container.registerSingleton((any RuleEngineProtocol).self) { _ in
            RuleEngine(context: context)
        }
        
        container.registerSingleton((any InsightsEngineProtocol).self) { _ in
            InsightsEngine(context: context)
        }
        
        container.registerSingleton((any BudgetMonitoringServiceProtocol).self) { c in
            BudgetMonitoringService(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        container.registerSingleton(CashflowForecastingService.self) { _ in
            CashflowForecastingService(
                context: context,
                backgroundContextProvider: backgroundContextProvider
            )
        }
        
        container.registerSingleton(RecurringTransactionService.self) { c in
            CoreDataRecurringTransactionService(
                recurringRepository: c.resolve(RecurringTransactionRepository.self),
                transactionRepository: c.resolve(TransactionRepository.self),
                context: context
            )
        }
        
        container.registerSingleton((any SubscriptionServiceProtocol).self) { _ in
            SubscriptionService()
        }
        
        container.registerSingleton(ScenarioPlanningService.self) { _ in
            ScenarioPlanningService(
                context: context,
                backgroundContextProvider: backgroundContextProvider
            )
        }
        
        container.registerSingleton(PrivacyManager.self) { _ in
            PrivacyManager(viewContext: context)
        }
        
        // MARK: - Register ViewModels (Transient)
        // ViewModels are registered as transient (new instance each time)
        
        container.register(BudgetCreationViewModel.self) { c in
            BudgetCreationViewModel(
                budgetRepository: c.resolve(BudgetRepository.self),
                budgetCategoryRepository: c.resolve(BudgetCategoryRepository.self),
                templateService: c.resolve(BudgetTemplateService.self),
                context: context
            )
        }
        
        return container
    }
    
    // MARK: - Test Container
    
    /// Creates a test DI container with mock dependencies
    /// - Returns: DIContainer configured for testing
    static func createTestContainer() -> DIContainer {
        let container = AppDIContainer()
        
        // Test container will be populated with mock implementations
        // This is a placeholder for future test infrastructure
        // Mock repositories and services will be registered here
        
        return container
    }
}
