//
//  InsightNotificationService.swift
//  ClariFi_iOS
//
//  Service for managing proactive insight notifications
//

import Foundation
import UserNotifications

class InsightNotificationService {
    
    static let shared = InsightNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Permission Management
    
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        return try await notificationCenter.requestAuthorization(options: options)
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleInsightNotification(_ insight: Insight) async throws {
        // Only schedule for high priority insights
        guard insight.priority >= .high else { return }
        
        // Check authorization
        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            print("Notification authorization not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = insight.title
        content.body = insight.description
        content.sound = .default
        content.badge = 1
        
        // Add category for actions
        content.categoryIdentifier = "INSIGHT_NOTIFICATION"
        
        // Add user info for handling
        content.userInfo = [
            "insightId": insight.id.uuidString,
            "insightType": insight.type.rawValue,
            "priority": insight.priority.rawValue
        ]
        
        // Schedule immediately for critical insights, or with delay for others
        let trigger: UNNotificationTrigger
        if insight.priority == .critical {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            // Schedule for next hour for high priority
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: insight.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    func scheduleBudgetAlert(category: String, percentUsed: Double, remaining: Decimal) async throws {
        let status = await checkAuthorizationStatus()
        guard status == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        
        if percentUsed >= 100 {
            content.title = "Budget Exceeded: \(category)"
            content.body = "You've exceeded your budget for \(category)"
        } else if percentUsed >= 90 {
            content.title = "Budget Alert: \(category)"
            content.body = String(format: "Only $%.2f remaining in your %@ budget",
                                Double(truncating: remaining as NSNumber),
                                category)
        } else {
            content.title = "Budget Warning: \(category)"
            content.body = String(format: "You've used %.0f%% of your %@ budget",
                                percentUsed,
                                category)
        }
        
        content.sound = .default
        content.categoryIdentifier = "BUDGET_ALERT"
        content.userInfo = [
            "category": category,
            "percentUsed": percentUsed,
            "type": "budgetAlert"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget_\(category)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    func scheduleSpendingTrendAlert(percentChange: Double, isIncrease: Bool) async throws {
        let status = await checkAuthorizationStatus()
        guard status == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = isIncrease ? "Spending Increased" : "Spending Decreased"
        content.body = String(format: "Your spending has %@ by %.1f%% this month",
                            isIncrease ? "increased" : "decreased",
                            abs(percentChange))
        content.sound = .default
        content.categoryIdentifier = "SPENDING_TREND"
        content.userInfo = [
            "percentChange": percentChange,
            "type": "spendingTrend"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "spending_trend_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(withId id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Notification Categories
    
    func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_INSIGHT",
            title: "View Details",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_INSIGHT",
            title: "Dismiss",
            options: .destructive
        )
        
        let insightCategory = UNNotificationCategory(
            identifier: "INSIGHT_NOTIFICATION",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let budgetCategory = UNNotificationCategory(
            identifier: "BUDGET_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let trendCategory = UNNotificationCategory(
            identifier: "SPENDING_TREND",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            insightCategory,
            budgetCategory,
            trendCategory
        ])
    }
}
