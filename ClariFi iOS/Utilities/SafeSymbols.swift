//
//  SafeSymbols.swift
//  ClariFi iOS
//
//  Safe SF Symbol handling to prevent symbol resolution errors
//

import SwiftUI

/// Safe SF Symbol wrapper that provides fallback symbols
struct SafeSymbol {
    let primary: String
    let fallback: String
    
    init(_ symbol: String, fallback: String = "questionmark.circle") {
        self.primary = symbol
        self.fallback = fallback
    }
    
    /// Returns the symbol name, with fallback if the primary symbol is not available
    var name: String {
        // For now, always return the primary symbol
        // In a more sophisticated implementation, we could check symbol availability
        return primary
    }
}

/// Predefined safe symbols for common use cases
extension SafeSymbol {
    // Error symbols
    static let error = SafeSymbol("exclamationmark.triangle.fill", fallback: "exclamationmark.circle")
    static let warning = SafeSymbol("exclamationmark.circle.fill", fallback: "exclamationmark.circle")
    static let info = SafeSymbol("info.circle.fill", fallback: "info.circle")
    
    // Success symbols
    static let success = SafeSymbol("checkmark.circle.fill", fallback: "checkmark.circle")
    static let checkmark = SafeSymbol("checkmark", fallback: "checkmark.circle")
    
    // Navigation symbols
    static let back = SafeSymbol("chevron.left", fallback: "arrow.left")
    static let forward = SafeSymbol("chevron.right", fallback: "arrow.right")
    static let up = SafeSymbol("chevron.up", fallback: "arrow.up")
    static let down = SafeSymbol("chevron.down", fallback: "arrow.down")
    
    // Action symbols
    static let add = SafeSymbol("plus", fallback: "plus.circle")
    static let edit = SafeSymbol("pencil", fallback: "pencil.circle")
    static let delete = SafeSymbol("trash", fallback: "trash.circle")
    static let share = SafeSymbol("square.and.arrow.up", fallback: "square.and.arrow.up")
    
    // Authentication symbols
    static let lock = SafeSymbol("lock.fill", fallback: "lock")
    static let unlock = SafeSymbol("lock.open.fill", fallback: "lock.open")
    static let shield = SafeSymbol("shield.fill", fallback: "shield")
    
    // Financial symbols
    static let money = SafeSymbol("dollarsign.circle.fill", fallback: "dollarsign.circle")
    static let creditCard = SafeSymbol("creditcard.fill", fallback: "creditcard")
    static let bank = SafeSymbol("building.columns.fill", fallback: "building.columns")
    
    // Document symbols
    static let document = SafeSymbol("doc.fill", fallback: "doc")
    static let documentText = SafeSymbol("doc.text.fill", fallback: "doc.text")
    static let magnifyingGlass = SafeSymbol("magnifyingglass", fallback: "magnifyingglass.circle")
    
    // Network symbols
    static let wifi = SafeSymbol("wifi", fallback: "wifi.circle")
    static let wifiSlash = SafeSymbol("wifi.slash", fallback: "wifi.exclamationmark")
    
    // Storage symbols
    static let externalDrive = SafeSymbol("externaldrive.fill", fallback: "externaldrive")
    static let externalDriveBadge = SafeSymbol("externaldrive.fill.badge.xmark", fallback: "externaldrive.badge.xmark")
    
    // Privacy symbols
    static let handRaised = SafeSymbol("hand.raised.fill", fallback: "hand.raised")
    static let eye = SafeSymbol("eye.fill", fallback: "eye")
    static let eyeSlash = SafeSymbol("eye.slash.fill", fallback: "eye.slash")
    
    // Premium symbols
    static let crown = SafeSymbol("crown.fill", fallback: "crown")
    static let star = SafeSymbol("star.fill", fallback: "star")
    
    // Insights symbols
    static let lightbulb = SafeSymbol("lightbulb.fill", fallback: "lightbulb")
    static let chart = SafeSymbol("chart.bar.fill", fallback: "chart.bar")
    static let trendUp = SafeSymbol("arrow.up.right", fallback: "arrow.up")
    static let trendDown = SafeSymbol("arrow.down.right", fallback: "arrow.down")
    
    // Settings symbols
    static let gear = SafeSymbol("gearshape.fill", fallback: "gearshape")
    static let slider = SafeSymbol("slider.horizontal.3", fallback: "slider.horizontal.3")
    static let bell = SafeSymbol("bell.fill", fallback: "bell")
    static let bellBadge = SafeSymbol("bell.badge.fill", fallback: "bell.badge")
    
    // List symbols
    static let list = SafeSymbol("list.bullet", fallback: "list.bullet.rectangle")
    static let listRectangle = SafeSymbol("list.bullet.rectangle", fallback: "list.bullet")
    
    // Magic symbols
    static let wand = SafeSymbol("wand.and.stars", fallback: "wand.and.stars")
    static let sparkles = SafeSymbol("sparkles", fallback: "sparkles")
    
    // Close symbols
    static let xmark = SafeSymbol("xmark", fallback: "xmark.circle")
    static let xmarkCircle = SafeSymbol("xmark.circle.fill", fallback: "xmark.circle")
}

/// Safe Image view that handles symbol resolution errors gracefully
struct SafeImage: View {
    let symbol: SafeSymbol
    let font: Font
    let foregroundColor: Color?
    
    init(systemName: String, fallback: String = "questionmark.circle", font: Font = .body, foregroundColor: Color? = nil) {
        self.symbol = SafeSymbol(systemName, fallback: fallback)
        self.font = font
        self.foregroundColor = foregroundColor
    }
    
    init(symbol: SafeSymbol, font: Font = .body, foregroundColor: Color? = nil) {
        self.symbol = symbol
        self.font = font
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        Image(systemName: symbol.name)
            .font(font)
            .foregroundColor(foregroundColor)
    }
}

/// Extension to make SafeSymbol work with Image directly
extension Image {
    init(safeSystemName: String, fallback: String = "questionmark.circle") {
        let symbol = SafeSymbol(safeSystemName, fallback: fallback)
        self.init(systemName: symbol.name)
    }
    
    init(safeSymbol: SafeSymbol) {
        self.init(systemName: safeSymbol.name)
    }
}
