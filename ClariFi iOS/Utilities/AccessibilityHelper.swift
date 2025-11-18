//
//  AccessibilityHelper.swift
//  ClariFi iOS
//
//  Accessibility utilities and helpers
//

import SwiftUI

// MARK: - Accessibility Labels

struct AccessibilityLabels {
    // Navigation
    static let dashboardTab = "Dashboard tab"
    static let transactionsTab = "Transactions tab"
    static let budgetTab = "Budget tab"
    static let insightsTab = "Insights tab"
    static let premiumTab = "Premium features tab"
    
    // Actions
    static let uploadStatement = "Upload bank statement"
    static let uploadStatementButton = "Upload bank statement"
    static let addTransaction = "Add new transaction manually"
    static let addTransactionButton = "Add new transaction manually"
    static let saveTransaction = "Save transaction"
    static let cancelAction = "Cancel"
    static let deleteTransaction = "Delete transaction"
    static let editTransaction = "Edit transaction"
    
    // Transaction rows
    static let transactionRow = "Transaction row"
    
    // Transaction fields
    static let transactionDate = "Transaction date"
    static let merchantName = "Merchant name"
    static let transactionAmount = "Transaction amount"
    static let transactionCategory = "Transaction category"
    static let transactionNotes = "Transaction notes"
    
    // Budget
    static let budgetAmount = "Budget amount"
    static let budgetCategory = "Budget category"
    static let budgetProgress = "Budget progress"
    
    // Status
    static let loading = "Loading"
    static let processing = "Processing"
    static let error = "Error"
    static let success = "Success"
    
    // Onboarding
    static let onboardingWelcome = "Welcome to ClariFi"
    static let onboardingPrivacy = "Privacy settings"
    static let onboardingFeatures = "Features overview"
    static let onboardingAccountSetup = "Account setup"
    static let onboardingBiometric = "Biometric security setup"
    static let onboardingQuickStart = "Quick start options"
    static let onboardingFirstAction = "First action guidance"
    static let onboardingProgress = "Onboarding progress"
    static let onboardingNextStep = "Continue to next step"
    static let onboardingPreviousStep = "Go back to previous step"
    static let onboardingSkip = "Skip this step"
    static let onboardingComplete = "Complete onboarding"
}

// MARK: - Accessibility Hints

struct AccessibilityHints {
    // Navigation
    static let dashboardTab = "View your financial dashboard and spending summary"
    static let transactionsTab = "View and manage your transactions"
    static let budgetTab = "View and manage your budgets"
    static let insightsTab = "View spending insights and recommendations"
    static let premiumTab = "Access premium features"
    
    // Actions
    static let uploadStatement = "Upload a bank statement to import transactions"
    static let uploadStatementButton = "Upload a bank statement to import transactions"
    static let addTransaction = "Manually enter a new transaction"
    static let addTransactionButton = "Manually enter a new transaction"
    static let saveTransaction = "Save this transaction to your account"
    static let deleteTransaction = "Remove this transaction permanently"
    static let editTransaction = "Modify transaction details"
    
    // Transaction
    static let transactionRow = "Double tap to view transaction details"
    static let merchantSuggestion = "Double tap to select this merchant"
    
    // Budget
    static let budgetProgress = "Shows spending progress for this budget category"
    
    // Onboarding
    static let onboardingWelcome = "Swipe left to continue through onboarding"
    static let onboardingPrivacy = "Select your preferred privacy mode"
    static let onboardingFeatures = "Learn about ClariFi features"
    static let onboardingAccountSetup = "Add accounts to track your finances"
    static let onboardingBiometric = "Enable biometric authentication for security"
    static let onboardingQuickStart = "Choose how you want to get started"
    static let onboardingFirstAction = "Complete your first action to start using ClariFi"
    static let onboardingNextStep = "Swipe left or tap to continue"
    static let onboardingPreviousStep = "Swipe right or tap to go back"
    static let onboardingSkip = "Skip this step and use default settings"
}

// MARK: - Accessibility Values

extension Decimal {
    var accessibleCurrencyValue: String {
        let value = CurrencyFormatter.shared.formatSync(self, currency: .usd)
        return value.replacingOccurrences(of: "$", with: "dollars ")
    }
}

extension Date {
    var accessibleDateValue: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

extension Float {
    var accessiblePercentageValue: String {
        return "\(Int(self * 100)) percent"
    }
}

// MARK: - View Extensions

extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleTextField(label: String, value: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
    }
    
    func accessibleHeading(_ level: AccessibilityHeadingLevel = .h1) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
    }
    
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    case success
    case warning
    case error
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    
    func trigger() {
        // Check if haptic feedback is available
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        do {
            switch self {
            case .success:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                
            case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                
            case .selection:
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                
            case .impact(let style):
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
        } catch {
            // Silently ignore haptic feedback errors (common in simulator)
            // This prevents the haptic pattern library errors from appearing in logs
        }
    }
}

// MARK: - Dynamic Type Support

struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var name: String
    var size: CGFloat
    
    func body(content: Content) -> some View {
        let scaledSize = UIFontMetrics.default.scaledValue(for: size)
        return content.font(.custom(name, size: scaledSize))
    }
}

extension View {
    func scaledFont(name: String, size: CGFloat) -> some View {
        self.modifier(ScaledFont(name: name, size: size))
    }
}

// MARK: - Accessibility Announcements

struct AccessibilityAnnouncement {
    static func announce(_ message: String, delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    static func announceScreenChange(to element: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
    
    static func announceLayoutChange(to element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

// MARK: - Color Contrast Utilities

struct ColorContrast {
    /// Check if color contrast meets WCAG AA standards (4.5:1 for normal text)
    static func meetsWCAGAA(foreground: Color, background: Color) -> Bool {
        return contrastRatio(foreground: foreground, background: background) >= 4.5
    }
    
    /// Check if color contrast meets WCAG AAA standards (7:1 for normal text)
    static func meetsWCAGAAA(foreground: Color, background: Color) -> Bool {
        return contrastRatio(foreground: foreground, background: background) >= 7.0
    }
    
    /// Calculate contrast ratio between two colors
    static func contrastRatio(foreground: Color, background: Color) -> Double {
        let fgLuminance = relativeLuminance(foreground)
        let bgLuminance = relativeLuminance(background)
        
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculate relative luminance of a color
    private static func relativeLuminance(_ color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = linearize(red)
        let g = linearize(green)
        let b = linearize(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Linearize RGB component
    private static func linearize(_ component: CGFloat) -> Double {
        let c = Double(component)
        if c <= 0.03928 {
            return c / 12.92
        } else {
            return pow((c + 0.055) / 1.055, 2.4)
        }
    }
    
    /// Get accessible text color (black or white) for a given background
    static func accessibleTextColor(for background: Color) -> Color {
        let luminance = relativeLuminance(background)
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Accessibility Testing

struct AccessibilityTesting {
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if reduce motion is enabled
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if reduce transparency is enabled
    static var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }
    
    /// Check if bold text is enabled
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
    
    /// Check if button shapes are enabled
    static var isButtonShapesEnabled: Bool {
        UIAccessibility.buttonShapesEnabled
    }
    
    /// Check if grayscale is enabled
    static var isGrayscaleEnabled: Bool {
        UIAccessibility.isGrayscaleEnabled
    }
    
    /// Check if invert colors is enabled
    static var isInvertColorsEnabled: Bool {
        UIAccessibility.isInvertColorsEnabled
    }
    
    /// Print accessibility status for debugging
    static func printStatus() {
        print("\n♿️ Accessibility Status")
        print("=" * 60)
        print("VoiceOver: \(isVoiceOverRunning ? "ON" : "OFF")")
        print("Reduce Motion: \(isReduceMotionEnabled ? "ON" : "OFF")")
        print("Reduce Transparency: \(isReduceTransparencyEnabled ? "ON" : "OFF")")
        print("Bold Text: \(isBoldTextEnabled ? "ON" : "OFF")")
        print("Button Shapes: \(isButtonShapesEnabled ? "ON" : "OFF")")
        print("Grayscale: \(isGrayscaleEnabled ? "ON" : "OFF")")
        print("Invert Colors: \(isInvertColorsEnabled ? "ON" : "OFF")")
        print("=" * 60 + "\n")
    }
}

// MARK: - String Extension

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

