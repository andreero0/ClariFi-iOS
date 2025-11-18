//
//  AnalyticsViewModifier.swift
//  ClariFi_iOS
//
//  View modifier for automatic screen tracking
//

import SwiftUI

/// View modifier that automatically tracks screen views
struct AnalyticsScreenModifier: ViewModifier {
    let screenName: String
    let properties: [String: Any]?
    
    init(screenName: String, properties: [String: Any]? = nil) {
        self.screenName = screenName
        self.properties = properties
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Analytics.screen(screenName, properties: properties)
            }
    }
}

extension View {
    /// Track screen view when this view appears
    func trackScreen(_ name: String, properties: [String: Any]? = nil) -> some View {
        modifier(AnalyticsScreenModifier(screenName: name, properties: properties))
    }
}

/// View modifier for tracking button taps
struct AnalyticsButtonModifier: ViewModifier {
    let event: AnalyticsEvent
    let properties: [String: Any]?
    let action: () -> Void
    
    func body(content: Content) -> some View {
        Button(action: {
            Analytics.track(event, properties: properties)
            action()
        }) {
            content
        }
    }
}

extension View {
    /// Track an event when this button is tapped
    func trackTap(event: AnalyticsEvent, properties: [String: Any]? = nil, action: @escaping () -> Void) -> some View {
        modifier(AnalyticsButtonModifier(event: event, properties: properties, action: action))
    }
}

/// Helper for tracking errors
extension Error {
    func track(context: [String: Any]? = nil) {
        Analytics.captureException(self, context: context)
    }
}
