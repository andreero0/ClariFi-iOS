//
//  ClariFi_iOSApp.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import SwiftUI
import AppIntents
import OSLog

@main
struct ClariFi_iOSApp: App {
    let persistenceController = PersistenceController.shared
    let diContainer: DIContainer
    
    private let logger = Logger(subsystem: "com.clarifi.ios", category: "DIContainer")
    
    init() {
        // Initialize DI container first
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Initializing DI container...")
        
        do {
            diContainer = AppDIContainer.createProductionContainer()
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("DI container initialized successfully in \(String(format: "%.2f", timeElapsed * 1000))ms")
            
            // Log registered dependencies count for debugging
            logger.debug("DI container ready with all dependencies registered")
            
            // Inject analytics service from DI container and initialize
            let analyticsService = diContainer.resolve(AnalyticsServiceProtocol.self)
            Analytics.setService(analyticsService)
            Analytics.initialize()
            
        } catch {
            logger.error("Failed to initialize DI container: \(error)")
            // Create a minimal container as fallback
            diContainer = AppDIContainer()
        }
        
        // Configure app settings based on environment
        if Configuration.isSimulator {
            // Disable haptic feedback in simulator to prevent pattern library errors
            UserDefaults.standard.set(false, forKey: "HapticFeedbackEnabled")
        }
        
        // Initialize memory manager to handle memory warnings
        _ = MemoryManager.shared
        
        // Initialize error handler to prevent crashes
        _ = ErrorHandler.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .withDIContainer(diContainer)
                .handleErrors()
        }
    }
}
