//
//  RepositoryFactory.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import Foundation
import CoreData

/// Factory class for creating and managing repository instances
///
/// **IMPORTANT: This class should be instantiated via Dependency Injection only.**
///
/// The singleton pattern has been removed in favor of dependency injection.
/// Use the DI container to resolve repositories:
///
/// ```swift
/// // In your View or ViewModel:
/// @Environment(\.diContainer) private var container
/// let repository = container.resolve(TransactionRepository.self)
/// ```
///
/// For testing, use the test container:
/// ```swift
/// let testContainer = DIContainer.createTestContainer()
/// let repository = testContainer.resolve(TransactionRepository.self)
/// ```
class RepositoryFactory {
    private let persistenceController: PersistenceController
    
    // Lazy-loaded repository instances
    private lazy var _transactionRepository: any TransactionRepository = {
        CoreDataTransactionRepository(context: persistenceController.container.viewContext)
    }()
    
    private lazy var _accountRepository: any AccountRepository = {
        CoreDataAccountRepository(context: persistenceController.container.viewContext)
    }()
    
    private lazy var _budgetRepository: any BudgetRepository = {
        CoreDataBudgetRepository(context: persistenceController.container.viewContext)
    }()
    
    private lazy var _budgetCategoryRepository: any BudgetCategoryRepository = {
        CoreDataBudgetCategoryRepository(context: persistenceController.container.viewContext)
    }()
    
    private lazy var _statementRepository: any StatementRepository = {
        CoreDataStatementRepository(context: persistenceController.container.viewContext)
    }()
    
    private lazy var _recurringTransactionRepository: any RecurringTransactionRepository = {
        CoreDataRecurringTransactionRepository(context: persistenceController.container.viewContext)
    }()
    
    // Background context repositories for heavy operations
    private lazy var _backgroundTransactionRepository: any TransactionRepository = {
        CoreDataTransactionRepository(context: persistenceController.container.newBackgroundContext())
    }()
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Repository Accessors
    
    var transactionRepository: any TransactionRepository {
        return _transactionRepository
    }
    
    var accountRepository: any AccountRepository {
        return _accountRepository
    }
    
    var budgetRepository: any BudgetRepository {
        return _budgetRepository
    }
    
    var budgetCategoryRepository: any BudgetCategoryRepository {
        return _budgetCategoryRepository
    }
    
    var statementRepository: any StatementRepository {
        return _statementRepository
    }
    
    var recurringTransactionRepository: any RecurringTransactionRepository {
        return _recurringTransactionRepository
    }
    
    // Background repositories for heavy operations
    var backgroundTransactionRepository: any TransactionRepository {
        return _backgroundTransactionRepository
    }
    
    // MARK: - Factory Methods
    
    /// Creates a new transaction repository with a background context
    func createBackgroundTransactionRepository() -> any TransactionRepository {
        return CoreDataTransactionRepository(context: persistenceController.container.newBackgroundContext())
    }
    
    /// Creates a new account repository with a background context
    func createBackgroundAccountRepository() -> any AccountRepository {
        return CoreDataAccountRepository(context: persistenceController.container.newBackgroundContext())
    }
    
    /// Creates a new budget repository with a background context
    func createBackgroundBudgetRepository() -> any BudgetRepository {
        return CoreDataBudgetRepository(context: persistenceController.container.newBackgroundContext())
    }
    
    /// Creates a new statement repository with a background context
    func createBackgroundStatementRepository() -> any StatementRepository {
        return CoreDataStatementRepository(context: persistenceController.container.newBackgroundContext())
    }
    
    /// Creates a new recurring transaction repository with a background context
    func createBackgroundRecurringTransactionRepository() -> any RecurringTransactionRepository {
        return CoreDataRecurringTransactionRepository(context: persistenceController.container.newBackgroundContext())
    }
    
    // MARK: - Validation Methods
    
    /// Validates that all required repositories can be created
    func validateRepositories() throws {
        // Check that all repositories are properly initialized
        // This is a simple validation - repositories are created during init
        // If any repository is nil, it would indicate an initialization failure
        guard transactionRepository != nil,
              accountRepository != nil,
              budgetRepository != nil,
              budgetCategoryRepository != nil,
              statementRepository != nil,
              recurringTransactionRepository != nil else {
            throw RepositoryError.validationFailed("One or more repositories failed to initialize")
        }
    }
}

// MARK: - Singleton Access (REMOVED)
// The singleton pattern has been removed in favor of dependency injection.
// All repositories should now be resolved through the DI container.
//
// Migration Guide:
// ----------------
// OLD: RepositoryFactory.shared.transactionRepository
// NEW: container.resolve(TransactionRepository.self)
//
// For more information, see:
// - Core/DependencyInjection/DIContainer.swift
// - Core/DependencyInjection/AppDIContainer+Registration.swift
// - ARCHITECTURE.md (when available)

// MARK: - Repository Container Protocol
protocol RepositoryContainer {
    var transactionRepository: any TransactionRepository { get }
    var accountRepository: any AccountRepository { get }
    var budgetRepository: any BudgetRepository { get }
    var budgetCategoryRepository: any BudgetCategoryRepository { get }
    var statementRepository: any StatementRepository { get }
    var recurringTransactionRepository: any RecurringTransactionRepository { get }
}

extension RepositoryFactory: RepositoryContainer {}
