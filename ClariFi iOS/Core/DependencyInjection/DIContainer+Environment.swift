//
//  DIContainer+Environment.swift
//  ClariFi iOS
//
//  Created for SwiftUI environment integration with DI container
//

import SwiftUI

// MARK: - Environment Key

/// Environment key for accessing the DI container in SwiftUI views
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = AppDIContainer.createProductionContainer()
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    /// Access the DI container from the SwiftUI environment
    ///
    /// Usage:
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.diContainer) private var container
    ///
    ///     var body: some View {
    ///         // Use container to resolve dependencies
    ///     }
    /// }
    /// ```
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject a DI container into the SwiftUI environment
    ///
    /// This modifier makes the container available to all child views via `@Environment(\.diContainer)`
    ///
    /// Usage:
    /// ```swift
    /// ContentView()
    ///     .withDIContainer(container)
    /// ```
    ///
    /// - Parameter container: The DI container to inject into the environment
    /// - Returns: A view with the container injected into its environment
    func withDIContainer(_ container: DIContainer) -> some View {
        environment(\.diContainer, container)
    }
}
