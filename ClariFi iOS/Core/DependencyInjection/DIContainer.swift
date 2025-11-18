//
//  DIContainer.swift
//  ClariFi iOS
//
//  Created by Kiro
//

import Foundation

/// Protocol defining the dependency injection container interface
/// Supports both singleton and transient lifecycle patterns
protocol DIContainer {
    /// Register a transient dependency (new instance created each time)
    /// - Parameters:
    ///   - type: The type to register
    ///   - factory: Factory closure that creates instances of the type
    func register<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    
    /// Register a singleton dependency (single instance created and cached)
    /// - Parameters:
    ///   - type: The type to register
    ///   - factory: Factory closure that creates the singleton instance
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
    
    /// Resolve a dependency from the container
    /// - Parameter type: The type to resolve
    /// - Returns: An instance of the requested type
    /// - Note: Crashes with fatalError if the type is not registered
    func resolve<T>(_ type: T.Type) -> T
    
    /// Attempt to resolve a dependency from the container
    /// - Parameter type: The type to resolve
    /// - Returns: An instance of the requested type, or nil if not registered
    func resolveOptional<T>(_ type: T.Type) -> T?
    
    /// Reset the container, clearing all singleton instances
    /// Useful for testing scenarios
    func reset()
}