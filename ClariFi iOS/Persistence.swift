//
//  Persistence.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for preview
        let sampleAccount = Account(context: viewContext)
        sampleAccount.id = UUID()
        sampleAccount.name = "Sample Checking"
        sampleAccount.type = "checking"
        sampleAccount.lastFourDigits = "1234"
        sampleAccount.isActive = true
        sampleAccount.isDefault = false
        sampleAccount.createdAt = Date()
        sampleAccount.updatedAt = Date()
        
        let sampleTransaction = Transaction(context: viewContext)
        sampleTransaction.id = UUID()
        sampleTransaction.date = Date()
        sampleTransaction.merchant = "Sample Store"
        sampleTransaction.amount = NSDecimalNumber(value: 25.99)
        sampleTransaction.currency = "USD"
        sampleTransaction.category = "Shopping"
        sampleTransaction.confidence = 0.95
        sampleTransaction.isManual = false
        sampleTransaction.createdAt = Date()
        sampleTransaction.updatedAt = Date()
        sampleTransaction.account = sampleAccount
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ClariFi_iOS")
        
        // Ensure we have at least one store description
        if container.persistentStoreDescriptions.isEmpty {
            let storeDescription = NSPersistentStoreDescription()
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        if inMemory {
            // For in-memory store, use a temporary URL
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure data protection and encryption
            configureDataProtection()
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Log error for debugging
                print("Core Data error: \(error), \(error.userInfo)")

                // Try to recover from common CoreData errors
                if PersistenceController.shouldAttemptRecovery(for: error) {
                    PersistenceController.attemptStoreRecovery(storeDescription: storeDescription)
                } else {
                    // If recovery is not possible, crash with detailed error info
                    fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
                }
            } else {
                print("Core Data store loaded successfully")
            }
        })
        
        // Configure context for optimal performance and privacy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable persistent history tracking for data sync
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
    }
    
    private func configureDataProtection() {
        guard let storeDescription = container.persistentStoreDescriptions.first else { return }
        
        // Enable data protection when device is locked
        storeDescription.setOption(FileProtectionType.complete as NSString, 
                                 forKey: NSPersistentStoreFileProtectionKey)
        
        // Configure SQLite options for better security and performance
        // Use WAL mode for better concurrency (this replaces DELETE mode)
        storeDescription.setOption("WAL" as NSString, 
                                 forKey: "journal_mode")
        storeDescription.setOption("1" as NSString, 
                                 forKey: "secure_delete")
        
        // Additional SQLite optimizations
        storeDescription.setOption("1" as NSString, 
                                 forKey: "synchronous")
        storeDescription.setOption("1000" as NSString, 
                                 forKey: "cache_size")
        
        // Ensure the store directory exists
        if let storeURL = storeDescription.url {
            let storeDirectory = storeURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: storeDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        }
    }
    
    /// Determines if we should attempt recovery for a given error
    private static func shouldAttemptRecovery(for error: NSError) -> Bool {
        // Attempt recovery for common recoverable errors
        let recoverableErrors = [
            NSCocoaErrorDomain: [NSFileReadNoSuchFileError,
                                NSFileReadNoPermissionError,
                                NSFileWriteNoPermissionError,
                                NSFileWriteFileExistsError],
            NSPOSIXErrorDomain: [ENOENT, EACCES, EPERM] // File not found, permission denied, etc.
        ]
        
        if let domainErrors = recoverableErrors[error.domain] {
            return domainErrors.contains { ($0 as? Int) == error.code }
        }
        
        return false
    }
    
    /// Attempts to recover from store loading errors
    private static func attemptStoreRecovery(storeDescription: NSPersistentStoreDescription) {
        print("Attempting Core Data store recovery...")
        
        // Try to remove the problematic store files and recreate
        if let storeURL = storeDescription.url {
            let storeDirectory = storeURL.deletingLastPathComponent()
            let storeName = storeURL.lastPathComponent
            
            // Remove all related files
            let fileManager = FileManager.default
            let relatedFiles = [
                storeName,
                "\(storeName)-wal",
                "\(storeName)-shm"
            ]
            
            for fileName in relatedFiles {
                let fileURL = storeDirectory.appendingPathComponent(fileName)
                try? fileManager.removeItem(at: fileURL)
            }
            
            // Ensure directory exists
            try? fileManager.createDirectory(at: storeDirectory, 
                                           withIntermediateDirectories: true, 
                                           attributes: nil)
            
            print("Store recovery completed - removed problematic files")
        }
    }
    
    /// Saves the Core Data context with error handling
    func save() throws {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
                // In production, you might want to show user-friendly error
                throw PersistenceError.saveFailed(nsError)
            }
        }
    }
    
    /// Performs a background save operation
    func saveInBackground() async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Deletes all data from the persistent store
    func deleteAllData() async throws {
        let context = container.newBackgroundContext()
        
        try await context.perform {
            // Delete all entities in dependency order
            let entityNames = ["Transaction", "BudgetCategory", "Budget", "Statement", "Account"]
            
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as? [NSManagedObjectID]
                let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, 
                                                  into: [self.container.viewContext])
            }
            
            try context.save()
        }
    }
}

// MARK: - Error Types
enum PersistenceError: LocalizedError {
    case saveFailed(NSError)
    case fetchFailed(NSError)
    case deleteFailed(NSError)
    case migrationFailed(NSError)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Failed to migrate data: \(error.localizedDescription)"
        }
    }
}
