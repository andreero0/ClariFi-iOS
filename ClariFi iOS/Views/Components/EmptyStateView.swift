//
//  EmptyStateView.swift
//  ClariFi iOS
//
//  Reusable empty state component
//

import SwiftUI

/// A view that displays when there's no content to show, with an optional call-to-action.
///
/// Empty states help users understand why content is missing and guide them toward
/// taking action to populate the view.
///
/// ## Usage
/// ```swift
/// if transactions.isEmpty {
///     EmptyStateView.noTransactions {
///         // Handle add transaction action
///     }
/// }
/// ```
///
/// ## Accessibility
/// - Icon is hidden from VoiceOver (decorative)
/// - Title and message are combined into single announcement
/// - Action button has clear label and hint
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action button (optional)
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
                .accessibilityLabel(actionTitle)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Creates an empty state for when there are no transactions.
    ///
    /// - Parameter action: Closure to execute when "Add Transaction" is tapped
    /// - Returns: A configured empty state view
    static func noTransactions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet",
            title: "No Transactions Yet",
            message: "Add your first transaction to start tracking your finances",
            actionTitle: "Add Transaction",
            action: action
        )
    }
    
    /// Creates an empty state for when there's insufficient data for insights.
    ///
    /// - Parameter action: Closure to execute when "Add Transaction" is tapped
    /// - Returns: A configured empty state view
    static func insufficientData(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "lightbulb",
            title: "Not Enough Data",
            message: "Add more transactions to see personalized insights",
            actionTitle: "Add Transaction",
            action: action
        )
    }
    
    /// Creates an empty state for when no budget has been set.
    ///
    /// - Parameter action: Closure to execute when "Create Budget" is tapped
    /// - Returns: A configured empty state view
    static func noBudget(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "target",
            title: "No Budget Set",
            message: "Create a budget to track your spending goals",
            actionTitle: "Create Budget",
            action: action
        )
    }
    
    /// Empty state for no accounts
    static func noAccounts(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "creditcard",
            title: "No Accounts",
            message: "Add an account to start tracking your finances",
            actionTitle: "Add Account",
            action: action
        )
    }
}

// MARK: - Preview

#Preview("No Transactions") {
    EmptyStateView.noTransactions {
        print("Add transaction tapped")
    }
}

#Preview("Insufficient Data") {
    EmptyStateView.insufficientData {
        print("Add transaction tapped")
    }
}

#Preview("No Budget") {
    EmptyStateView.noBudget {
        print("Create budget tapped")
    }
}

#Preview("Custom") {
    EmptyStateView(
        icon: "doc.text",
        title: "No Documents",
        message: "You haven't uploaded any documents yet",
        actionTitle: "Upload Document",
        action: {
            print("Upload tapped")
        }
    )
}
