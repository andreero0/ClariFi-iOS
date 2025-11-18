//
//  AppDIContainer.swift
//  ClariFi iOS
//
//  Created by Kiro
//

import Foundation

/// Errors that can occur during dependency injection operations
enum DIError: Error, LocalizedError {
    case circularDependency(String)
    case resolutionFailed(String)
    case duplicateRegistration(String)
    
    var errorDescription: String? {
        switch self {
        case .circularDependency(let cycle):
            return "Circular dependency detected: \(cycle)"
        case .resolutionFailed(let type):
            return "Failed to resolve dependency for type: \(type)"
        case .duplicateRegistration(let type):
            return "Duplicate registration attempted for type: \(type)"
        }
    }
}

/// Concrete implementation of the dependency injection container
/// Manages registration and resolution of dependencies with singleton and transient lifecycles
final class AppDIContainer: DIContainer {
    // MARK: - Private Properties
    
    /// Storage for transient factory closures (new instance each time)
    private var factories: [String: (DIContainer) -> Any] = [:]
    
    /// Storage for explicit transient factory closures (new instance each time)
    private var transientFactories: [String: (DIContainer) -> Any] = [:]
    
    /// Storage for singleton instances (cached after first creation)
    private var singletons: [String: Any] = [:]
    
    /// Storage for singleton factory closures (used to create singletons on first access)
    private var singletonFactories: [String: (DIContainer) -> Any] = [:]
    
    /// Lock for thread-safe access to container state
    /// Using NSRecursiveLock to allow nested resolve calls from factory closures
    private let lock = NSRecursiveLock()
    
    /// Track resolution stack to detect cycles
    private var resolutionStack: [String] = []
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - DIContainer Protocol Implementation
    
    func register<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        singletonFactories[key] = factory
    }
    
    func registerTransient<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        transientFactories[key] = factory
    }
    
    func resolve<T>(throwing type: T.Type) throws -> T {
        let key = String(describing: type)
        
        // Check for circular dependency
        if resolutionStack.contains(key) {
            let cycle = resolutionStack.joined(separator: " -> ") + " -> " + key
            throw DIError.circularDependency(cycle)
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        // Check if it's a singleton that's already been created
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Add to resolution stack for cycle detection
        resolutionStack.append(key)
        defer { resolutionStack.removeLast() }
        
        // Check if it's a singleton factory (create and cache)
        if let factory = singletonFactories[key] {
            // Release lock before factory invocation to prevent deadlock
            lock.unlock()
            let instance = factory(self)
            lock.lock()
            
            guard let typedInstance = instance as? T else {
                throw DIError.resolutionFailed(key)
            }
            
            singletons[key] = typedInstance
            return typedInstance
        }
        
        // Check if it's an explicit transient factory (create new instance)
        if let factory = transientFactories[key] {
            // Release lock before factory invocation to prevent deadlock
            lock.unlock()
            let instance = factory(self)
            lock.lock()
            
            guard let typedInstance = instance as? T else {
                throw DIError.resolutionFailed(key)
            }
            
            return typedInstance
        }
        
        // Check if it's a regular transient factory (create new instance)
        if let factory = factories[key] {
            // Release lock before factory invocation to prevent deadlock
            lock.unlock()
            let instance = factory(self)
            lock.lock()
            
            guard let typedInstance = instance as? T else {
                throw DIError.resolutionFailed(key)
            }
            
            return typedInstance
        }
        
        // No registration found
        throw DIError.resolutionFailed(key)
    }
    
    // Non-throwing version for backward compatibility
    func resolve<T>(_ type: T.Type) -> T {
        do {
            return try resolve(throwing: type) as T
        } catch {
            // Maintain backward compatibility by crashing with detailed error
            if let diError = error as? DIError {
                switch diError {
                case .circularDependency(let cycle):
                    fatalError("""
                        DI Container Error: Circular dependency detected!
                        Resolution cycle: \(cycle)
                        
                        This indicates a circular dependency in your DI registrations.
                        Review your factory closures to ensure they don't create cycles.
                        """)
                case .resolutionFailed(let type):
                    fatalError("""
                        DI Container Error: No registration found for type '\(type)'
                        
                        Make sure to register this type in the DI container before attempting to resolve it.
                        
                        Example:
                        container.register(\(type).self) { container in
                            // Create and return instance
                        }
                        """)
                case .duplicateRegistration(let type):
                    fatalError("DI Container Error: Duplicate registration for type '\(type)'")
                }
            }
            fatalError("DI Container Error: Unexpected error during resolution: \(error)")
        }
    }
    
    func resolveOptional<T>(_ type: T.Type) -> T? {
        do {
            return try resolve(throwing: type) as T
        } catch {
            // Return nil for any resolution failure in optional context
            if let diError = error as? DIError {
                switch diError {
                case .circularDependency(let cycle):
                    print("DI Container Warning: Circular dependency detected for optional resolve: \(cycle)")
                case .resolutionFailed(let type):
                    print("DI Container Warning: Failed to resolve optional dependency for type: \(type)")
                case .duplicateRegistration(let type):
                    print("DI Container Warning: Duplicate registration for type: \(type)")
                }
            }
            return nil
        }
    }
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        // Clear all singleton instances
        // This allows singletons to be recreated on next access
        singletons.removeAll()
    }
}

// MARK: - Debug Helpers

extension AppDIContainer {
    /// Get a list of all registered types for debugging purposes
    var registeredTypes: [String] {
        lock.lock()
        defer { lock.unlock() }
        
        let regularTransientTypes = Array(factories.keys)
        let explicitTransientTypes = Array(transientFactories.keys)
        let singletonTypes = Array(singletonFactories.keys)
        return (regularTransientTypes + explicitTransientTypes + singletonTypes).sorted()
    }
    
    /// Check if a type is registered in the container
    func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        return factories[key] != nil || transientFactories[key] != nil || singletonFactories[key] != nil
    }
}
