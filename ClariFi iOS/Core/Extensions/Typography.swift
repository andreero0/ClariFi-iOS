//
//  Typography.swift
//  ClariFi iOS
//
//  Enhanced typography system following Apple's SF Pro guidelines and HIG 2024-2025
//

import SwiftUI

// MARK: - Typography System

struct Typography {
    
    // MARK: - Hero Numbers (Balance, Large Values)
    
    /// Hero balance display - 48pt SF Pro Display Bold
    static let heroBalance = Font.system(size: 48, weight: .bold, design: .rounded)
    
    /// Large metric values - 28pt SF Pro Display Bold
    static let largeMetric = Font.system(size: 28, weight: .bold, design: .rounded)
    
    /// Medium metric values - 24pt SF Pro Display Semibold
    static let mediumMetric = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    // MARK: - Headers and Titles
    
    /// Navigation title - 34pt SF Pro Text Bold
    static let navigationTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Large title - 28pt SF Pro Text Bold
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Title - 22pt SF Pro Text Bold
    static let title = Font.system(size: 22, weight: .bold, design: .default)
    
    /// Headline - 17pt SF Pro Text Semibold
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Subheadline - 15pt SF Pro Text Medium
    static let subheadline = Font.system(size: 15, weight: .medium, design: .default)
    
    // MARK: - Body Text
    
    /// Body text - 17pt SF Pro Text Regular
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Callout - 16pt SF Pro Text Regular
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Footnote - 13pt SF Pro Text Regular
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Caption - 12pt SF Pro Text Regular
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Caption 2 - 11pt SF Pro Text Regular
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - System Font Styles (Dynamic Type Compatible)
    
    /// Use system font styles for Dynamic Type support
    static let systemLargeTitle = Font.largeTitle
    static let systemTitle = Font.title
    static let systemTitle2 = Font.title2
    static let systemTitle3 = Font.title3
    static let systemHeadline = Font.headline
    static let systemSubheadline = Font.subheadline
    static let systemBody = Font.body
    static let systemCallout = Font.callout
    static let systemFootnote = Font.footnote
    static let systemCaption = Font.caption
    static let systemCaption2 = Font.caption2
}

// MARK: - Typography Modifiers

extension View {
    
    /// Apply hero balance typography
    func heroBalanceStyle() -> some View {
        self.font(Typography.heroBalance)
            .dynamicTypeSize(.large ... .accessibility5)
    }
    
    /// Apply large metric typography
    func largeMetricStyle() -> some View {
        self.font(Typography.largeMetric)
            .dynamicTypeSize(.large ... .accessibility3)
    }
    
    /// Apply medium metric typography
    func mediumMetricStyle() -> some View {
        self.font(Typography.mediumMetric)
            .dynamicTypeSize(.large ... .accessibility2)
    }
    
    /// Apply navigation title typography
    func navigationTitleStyle() -> some View {
        self.font(Typography.navigationTitle)
            .dynamicTypeSize(.large ... .accessibility3)
    }
    
    /// Apply large title typography
    func largeTitleStyle() -> some View {
        self.font(Typography.largeTitle)
            .dynamicTypeSize(.large ... .accessibility3)
    }
    
    /// Apply title typography
    func titleStyle() -> some View {
        self.font(Typography.title)
            .dynamicTypeSize(.large ... .accessibility2)
    }
    
    /// Apply headline typography
    func headlineStyle() -> some View {
        self.font(Typography.headline)
            .dynamicTypeSize(.large ... .accessibility2)
    }
    
    /// Apply subheadline typography
    func subheadlineStyle() -> some View {
        self.font(Typography.subheadline)
            .dynamicTypeSize(.large ... .accessibility2)
    }
    
    /// Apply body typography
    func bodyStyle() -> some View {
        self.font(Typography.body)
            .dynamicTypeSize(.large ... .accessibility2)
    }
    
    /// Apply callout typography
    func calloutStyle() -> some View {
        self.font(Typography.callout)
            .dynamicTypeSize(.large ... .accessibility2)
    }
    
    /// Apply footnote typography
    func footnoteStyle() -> some View {
        self.font(Typography.footnote)
            .dynamicTypeSize(.large ... .accessibility1)
    }
    
    /// Apply caption typography
    func captionStyle() -> some View {
        self.font(Typography.caption)
            .dynamicTypeSize(.large ... .accessibility1)
    }
    
    /// Apply caption2 typography
    func caption2Style() -> some View {
        self.font(Typography.caption2)
            .dynamicTypeSize(.large ... .accessibility1)
    }
    
    // MARK: - System Font Modifiers (Dynamic Type)
    
    /// Apply system large title (Dynamic Type compatible)
    func systemLargeTitleStyle() -> some View {
        self.font(Typography.systemLargeTitle)
    }
    
    /// Apply system title (Dynamic Type compatible)
    func systemTitleStyle() -> some View {
        self.font(Typography.systemTitle)
    }
    
    /// Apply system title2 (Dynamic Type compatible)
    func systemTitle2Style() -> some View {
        self.font(Typography.systemTitle2)
    }
    
    /// Apply system title3 (Dynamic Type compatible)
    func systemTitle3Style() -> some View {
        self.font(Typography.systemTitle3)
    }
    
    /// Apply system headline (Dynamic Type compatible)
    func systemHeadlineStyle() -> some View {
        self.font(Typography.systemHeadline)
    }
    
    /// Apply system subheadline (Dynamic Type compatible)
    func systemSubheadlineStyle() -> some View {
        self.font(Typography.systemSubheadline)
    }
    
    /// Apply system body (Dynamic Type compatible)
    func systemBodyStyle() -> some View {
        self.font(Typography.systemBody)
    }
    
    /// Apply system callout (Dynamic Type compatible)
    func systemCalloutStyle() -> some View {
        self.font(Typography.systemCallout)
    }
    
    /// Apply system footnote (Dynamic Type compatible)
    func systemFootnoteStyle() -> some View {
        self.font(Typography.systemFootnote)
    }
    
    /// Apply system caption (Dynamic Type compatible)
    func systemCaptionStyle() -> some View {
        self.font(Typography.systemCaption)
    }
    
    /// Apply system caption2 (Dynamic Type compatible)
    func systemCaption2Style() -> some View {
        self.font(Typography.systemCaption2)
    }
}

// MARK: - Accessibility Extensions

extension View {
    
    /// Apply accessible heading trait for VoiceOver
    func accessibleHeading() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }
    
    /// Apply accessible button trait for VoiceOver
    func accessibleButton() -> some View {
        self.accessibilityAddTraits(.isButton)
    }
    
    /// Apply accessible link trait for VoiceOver
    func accessibleLink() -> some View {
        self.accessibilityAddTraits(.isLink)
    }
}

// MARK: - Preview Helpers

struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Hero Balance")
                        .heroBalanceStyle()
                        .foregroundColor(.primary)
                    
                    Text("Large Metric")
                        .largeMetricStyle()
                        .foregroundColor(.primary)
                    
                    Text("Medium Metric")
                        .mediumMetricStyle()
                        .foregroundColor(.primary)
                }
                
                Divider()
                
                Group {
                    Text("Navigation Title")
                        .navigationTitleStyle()
                        .foregroundColor(.primary)
                    
                    Text("Large Title")
                        .largeTitleStyle()
                        .foregroundColor(.primary)
                    
                    Text("Title")
                        .titleStyle()
                        .foregroundColor(.primary)
                    
                    Text("Headline")
                        .headlineStyle()
                        .foregroundColor(.primary)
                    
                    Text("Subheadline")
                        .subheadlineStyle()
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Group {
                    Text("Body Text")
                        .bodyStyle()
                        .foregroundColor(.primary)
                    
                    Text("Callout")
                        .calloutStyle()
                        .foregroundColor(.primary)
                    
                    Text("Footnote")
                        .footnoteStyle()
                        .foregroundColor(.secondary)
                    
                    Text("Caption")
                        .captionStyle()
                        .foregroundColor(.secondary)
                    
                    Text("Caption 2")
                        .caption2Style()
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Group {
                    Text("System Large Title (Dynamic Type)")
                        .systemLargeTitleStyle()
                        .foregroundColor(.primary)
                    
                    Text("System Title (Dynamic Type)")
                        .systemTitleStyle()
                        .foregroundColor(.primary)
                    
                    Text("System Headline (Dynamic Type)")
                        .systemHeadlineStyle()
                        .foregroundColor(.primary)
                    
                    Text("System Body (Dynamic Type)")
                        .systemBodyStyle()
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .navigationTitle("Typography System")
    }
}

#Preview {
    NavigationView {
        TypographyPreview()
    }
}
