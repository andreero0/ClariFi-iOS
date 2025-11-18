//
//  MainTabView.swift
//  ClariFi iOS
//
//  Main tab navigation structure for the app
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.diContainer) private var container
    // State Management: @StateObject is used for app-wide state objects that are owned
    // and created by this root view. These objects are then passed down via @EnvironmentObject
    // to child views that need access to shared state.
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                .accessibilityLabel("Home")
                .accessibilityHint("View your account balance and quick actions")
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
                .environmentObject(subscriptionViewModel)
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "chart.bar.fill")
                }
                .tag(1)
                .accessibilityLabel("Activity")
                .accessibilityHint("View transactions and insights")
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
                .environmentObject(subscriptionViewModel)
            
            PlanningView()
                .tabItem {
                    Label("Planning", systemImage: "slider.horizontal.3")
                }
                .tag(2)
                .accessibilityLabel("Planning")
                .accessibilityHint("Manage budget and app settings")
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appState)
                .environmentObject(subscriptionViewModel)
        }
        .sheet(isPresented: $subscriptionViewModel.showPaywall) {
            PaywallView()
        }
    }
}

// App-wide state management
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showingStatementUpload = false
    @Published var showingTransactionEntry = false
    @Published var shouldPresentBudgetCreation = false
    @Published var refreshTrigger = UUID()
    
    private var onboardingObserver: NSObjectProtocol?
    
    init() {
        onboardingObserver = NotificationCenter.default.addObserver(
            forName: .onboardingCompleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleOnboardingCompletion(notification)
        }
    }
    
    deinit {
        if let onboardingObserver {
            NotificationCenter.default.removeObserver(onboardingObserver)
        }
    }
    
    func refreshData() {
        refreshTrigger = UUID()
    }
    
    private func handleOnboardingCompletion(_ notification: Notification) {
        guard let actionRaw = notification.userInfo?["firstAction"] as? String,
              let action = FirstActionType(rawValue: actionRaw) else {
            return
        }
        
        switch action {
        case .uploadStatement:
            selectedTab = 0
            showingStatementUpload = true
        case .manualEntry:
            selectedTab = 0
            showingTransactionEntry = true
        case .createBudget:
            selectedTab = 2
            shouldPresentBudgetCreation = true
        }
    }
}

#Preview("Tab Navigation") {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(\.diContainer, AppDIContainer())
}

// Lightweight preview for faster loading
#Preview("Simple Tab") {
    TabView {
        Text("Dashboard")
            .tabItem {
                Label("Dashboard", systemImage: "chart.pie.fill")
            }
        
        Text("Transactions")
            .tabItem {
                Label("Transactions", systemImage: "list.bullet")
            }
        
        Text("Budget")
            .tabItem {
                Label("Budget", systemImage: "target")
            }
        
        Text("Insights")
            .tabItem {
                Label("Insights", systemImage: "lightbulb.fill")
            }
    }
}
