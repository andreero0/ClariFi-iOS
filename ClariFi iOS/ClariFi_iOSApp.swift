//
//  ClariFi_iOSApp.swift
//  ClariFi iOS
//
//  Created by aEro on 2025-10-10.
//

import SwiftUI

@main
struct ClariFi_iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
