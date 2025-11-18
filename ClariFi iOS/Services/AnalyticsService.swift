//
//  AnalyticsService.swift
//  ClariFi_iOS
//
//  Analytics and crash reporting service using PostHog
//  Privacy-conscious implementation with opt-in tracking
//

import Foundation
import SwiftUI

/// Analytics event types for tracking user interactions
enum AnalyticsEvent: String {
    // Onboarding & Setup
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case onboardingStepViewed = "onboarding_step_viewed"
    case onboardingStepCompleted = "onboarding_step_completed"
    case onboardingStepAbandoned = "onboarding_step_abandoned"
    case onboardingAccountCreated = "onboarding_account_created"
    case onboardingFirstActionSelected = "onboarding_first_action_selected"
    case privacyModeSelected = "privacy_mode_selected"
    
    // Statement Upload
    case statementUploadStarted = "statement_upload_started"
    case statementUploadCompleted = "statement_upload_completed"
    case statementUploadFailed = "statement_upload_failed"
    case statementUploadCancelled = "statement_upload_cancelled"
    case documentSourceSelected = "document_source_selected"
    
    // OCR & Parsing
    case ocrProcessingStarted = "ocr_processing_started"
    case ocrProcessingCompleted = "ocr_processing_completed"
    case ocrProcessingFailed = "ocr_processing_failed"
    case transactionsParsed = "transactions_parsed"
    case lowConfidenceDetected = "low_confidence_detected"
    
    // Transaction Management
    case transactionAdded = "transaction_added"
    case transactionEdited = "transaction_edited"
    case transactionDeleted = "transaction_deleted"
    case transactionCategorized = "transaction_categorized"
    case batchCategorizationApplied = "batch_categorization_applied"
    
    // Budget Management
    case budgetCreated = "budget_created"
    case budgetEdited = "budget_edited"
    case budgetDeleted = "budget_deleted"
    case budgetTemplateSelected = "budget_template_selected"
    case budgetAlertTriggered = "budget_alert_triggered"
    case budgetExceeded = "budget_exceeded"
    
    // Categorization & Rules
    case categoryRuleCreated = "category_rule_created"
    case categoryRuleEdited = "category_rule_edited"
    case categoryRuleDeleted = "category_rule_deleted"
    case categoryRuleApplied = "category_rule_applied"
    case merchantLearned = "merchant_learned"
    
    // Insights
    case insightGenerated = "insight_generated"
    case insightViewed = "insight_viewed"
    case insightDismissed = "insight_dismissed"
    case insightActionTaken = "insight_action_taken"
    case spendingTrendViewed = "spending_trend_viewed"
    
    // Premium Features
    case paywallViewed = "paywall_viewed"
    case subscriptionStarted = "subscription_started"
    case subscriptionCompleted = "subscription_completed"
    case subscriptionFailed = "subscription_failed"
    case subscriptionRestored = "subscription_restored"
    case premiumFeatureAccessed = "premium_feature_accessed"
    case cashflowForecastViewed = "cashflow_forecast_viewed"
    case scenarioPlanningUsed = "scenario_planning_used"
    
    // Privacy & Security
    case privacyDashboardViewed = "privacy_dashboard_viewed"
    case dataExported = "data_exported"
    case dataDeleted = "data_deleted"
    case processingModeChanged = "processing_mode_changed"
    case biometricAuthEnabled = "biometric_auth_enabled"
    case biometricAuthDisabled = "biometric_auth_disabled"
    case biometricAuthSuccess = "biometric_auth_success"
    case biometricAuthFailed = "biometric_auth_failed"
    
    // Navigation & UI
    case screenViewed = "screen_viewed"
    case tabSwitched = "tab_switched"
    case searchPerformed = "search_performed"
    case filterApplied = "filter_applied"
    case sortChanged = "sort_changed"
    
    // Errors & Crashes
    case errorOccurred = "error_occurred"
    case crashReported = "crash_reported"
    case recoveryAttempted = "recovery_attempted"
    
    // Recurring Transactions
    case recurringTransactionCreated = "recurring_transaction_created"
    case recurringTransactionExecuted = "recurring_transaction_executed"
    case recurringTransactionEdited = "recurring_transaction_edited"
    case recurringTransactionDeleted = "recurring_transaction_deleted"
    
    // Help & Support
    case helpViewed = "help_viewed"
    case aboutViewed = "about_viewed"
    case feedbackSubmitted = "feedback_submitted"
}

/// Analytics service protocol
protocol AnalyticsServiceProtocol {
    var isEnabled: Bool { get set }
    func initialize()
    func identify(userId: String, properties: [String: Any]?)
    func track(event: AnalyticsEvent, properties: [String: Any]?)
    func screen(name: String, properties: [String: Any]?)
    func setUserProperty(key: String, value: Any)
    func reset()
    func captureException(_ error: Error, context: [String: Any]?)
}

/// PostHog analytics implementation
class PostHogAnalyticsService: AnalyticsServiceProtocol {
    private let apiKey: String
    private let host: String
    private var userId: String?
    private var userProperties: [String: Any] = [:]
    private var sessionId: String
    private let sessionStartTime: Date
    
    // Event batching
    private var eventQueue: [AnalyticsEventData] = []
    private let batchSize = 10
    private let flushInterval: TimeInterval = 30.0 // 30 seconds
    private var flushTimer: Timer?
    private let queueLock = NSLock()
    
    // Cached formatter for performance
    private let dateFormatter = ISO8601DateFormatter()
    
    @AppStorage("analytics_enabled") var isEnabled: Bool = false
    @AppStorage("crash_reporting_enabled") private var crashReportingEnabled: Bool = false
    
    init() {
        // Load from configuration
        self.apiKey = Configuration.postHogAPIKey
        self.host = Configuration.postHogHost
        self.sessionId = UUID().uuidString
        self.sessionStartTime = Date()
        
        // For development, disable analytics if no API key is provided
        if apiKey.isEmpty {
            self.isEnabled = false
        } else {
            startFlushTimer()
        }
    }
    
    deinit {
        flushTimer?.invalidate()
        flushRemainingEvents()
    }
    
    func initialize() {
        guard !apiKey.isEmpty else {
            print("PostHog API key not configured. Analytics disabled.")
            return
        }
        
        if isEnabled {
            print("PostHog Analytics initialized")
            track(event: .onboardingStarted, properties: [
                "session_id": sessionId,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "device_model": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ])
        }
    }
    
    func identify(userId: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        self.userId = userId
        if let properties = properties {
            self.userProperties.merge(properties) { _, new in new }
        }
        
        sendEvent(type: "$identify", event: nil, properties: properties)
    }
    
    func track(event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        var enrichedProperties = properties ?? [:]
        enrichedProperties["session_id"] = sessionId
        enrichedProperties["session_duration"] = Date().timeIntervalSince(sessionStartTime)
        
        let eventData = AnalyticsEventData(
            type: "$capture",
            event: event.rawValue,
            properties: enrichedProperties,
            timestamp: Date()
        )
        
        addToBatch(eventData)
    }
    
    func screen(name: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        var screenProperties = properties ?? [:]
        screenProperties["screen_name"] = name
        
        track(event: .screenViewed, properties: screenProperties)
    }
    
    func setUserProperty(key: String, value: Any) {
        guard isEnabled else { return }
        
        userProperties[key] = value
        sendEvent(type: "$set", event: nil, properties: [key: value])
    }
    
    func reset() {
        userId = nil
        userProperties.removeAll()
        sessionId = UUID().uuidString
    }
    
    func captureException(_ error: Error, context: [String: Any]? = nil) {
        guard isEnabled && crashReportingEnabled else { return }
        
        var errorProperties: [String: Any] = [
            "error_type": String(describing: type(of: error)),
            "error_description": error.localizedDescription,
            "session_id": sessionId
        ]
        
        if let context = context {
            errorProperties.merge(context) { _, new in new }
        }
        
        // Add stack trace if available
        if let nsError = error as NSError? {
            errorProperties["error_domain"] = nsError.domain
            errorProperties["error_code"] = nsError.code
            errorProperties["error_user_info"] = nsError.userInfo.description
        }
        
        track(event: .errorOccurred, properties: errorProperties)
    }
    
    // MARK: - Private Methods
    
    private func sendEvent(type: String, event: String?, properties: [String: Any]?) {
        guard !apiKey.isEmpty else { return }
        
        var payload: [String: Any] = [
            "api_key": apiKey,
            "type": type,
            "distinct_id": userId ?? "anonymous_\(sessionId)",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let event = event {
            payload["event"] = event
        }
        
        var allProperties = userProperties
        if let properties = properties {
            allProperties.merge(properties) { _, new in new }
        }
        
        if !allProperties.isEmpty {
            payload["properties"] = allProperties
        }
        
        // Send to PostHog API
        sendToPostHog(payload: payload)
    }
    
    private func sendToPostHog(payload: [String: Any]) {
        guard let url = URL(string: "\(host)/capture/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("PostHog event failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("PostHog event sent successfully")
                    } else {
                        print("PostHog event failed with status: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        } catch {
            print("Failed to serialize PostHog payload: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Event Batching Methods
    
    private func addToBatch(_ event: AnalyticsEventData) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        eventQueue.append(event)
        
        // Flush if batch is full
        if eventQueue.count >= batchSize {
            flushEvents()
        }
    }
    
    private func flushEvents() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        guard !eventQueue.isEmpty else { return }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        
        sendBatch(eventsToSend)
    }
    
    private func sendEventImmediately(_ event: AnalyticsEventData) {
        sendBatch([event])
    }
    
    private func sendBatch(_ events: [AnalyticsEventData]) {
        guard !events.isEmpty else { return }
        
        Task {
            await sendEventsToPostHog(events)
        }
    }
    
    private func sendEventsToPostHog(_ events: [AnalyticsEventData]) async {
        guard let url = URL(string: "\(host)/capture/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare batch payload
        let batchPayload: [String: Any] = [
            "api_key": apiKey,
            "batch": events.map { event in
                var payload: [String: Any] = [
                    "type": event.type,
                    "distinct_id": userId ?? "anonymous_\(sessionId)",
                    "timestamp": dateFormatter.string(from: event.timestamp)
                ]
                
                if let eventName = event.event {
                    payload["event"] = eventName
                }
                
                var allProperties = userProperties
                if let properties = event.properties {
                    allProperties.merge(properties) { _, new in new }
                }
                
                if !allProperties.isEmpty {
                    payload["properties"] = allProperties
                }
                
                return payload
            }
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: batchPayload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("PostHog batch failed with status: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("PostHog batch failed: \(error.localizedDescription)")
        }
    }
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushEvents()
        }
    }
    
    private func flushRemainingEvents() {
        flushEvents()
    }
}

// MARK: - Supporting Types

private struct AnalyticsEventData {
    let type: String
    let event: String?
    let properties: [String: Any]?
    let timestamp: Date
}

/// Analytics helper for easy access throughout the app
/// This class acts as a facade to the injected analytics service
class Analytics {
    private static var _service: AnalyticsServiceProtocol?
    
    /// Set the analytics service instance (called during app initialization)
    static func setService(_ service: AnalyticsServiceProtocol) {
        _service = service
    }
    
    /// Get the current analytics service
    private static var service: AnalyticsServiceProtocol {
        guard let service = _service else {
            fatalError("Analytics service not initialized. Call Analytics.setService() during app initialization.")
        }
        return service
    }
    
    static func initialize() {
        service.initialize()
    }
    
    static func identify(userId: String, properties: [String: Any]? = nil) {
        service.identify(userId: userId, properties: properties)
    }
    
    static func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        service.track(event: event, properties: properties)
    }
    
    static func screen(_ name: String, properties: [String: Any]? = nil) {
        service.screen(name: name, properties: properties)
    }
    
    static func setUserProperty(key: String, value: Any) {
        service.setUserProperty(key: key, value: value)
    }
    
    static func reset() {
        service.reset()
    }
    
    static func captureException(_ error: Error, context: [String: Any]? = nil) {
        service.captureException(error, context: context)
    }
}
