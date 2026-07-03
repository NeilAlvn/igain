//
//  Theme.swift
//  Igain
//

import SwiftUI

/// Cronometer-inspired palette. Colors adapt between light and dark mode.
enum Theme {
    /// Brand accent — Cronometer-style amber/gold.
    static let accent = Color(red: 0.96, green: 0.62, blue: 0.04)

    /// Macro colors used consistently across rings, bars, and labels.
    static let protein = Color(red: 0.91, green: 0.30, blue: 0.24)
    static let carbs = Color(red: 0.15, green: 0.68, blue: 0.62)
    static let fat = Color(red: 0.95, green: 0.77, blue: 0.06)

    static let calorieRing = accent
    static let burned = Color(red: 0.35, green: 0.56, blue: 0.94)

    /// Water tracker blue.
    static let water = Color(red: 0.20, green: 0.62, blue: 0.90)

    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)

    static let positive = Color(red: 0.30, green: 0.72, blue: 0.35)
    static let negative = Color(red: 0.91, green: 0.30, blue: 0.24)
}

extension View {
    /// Standard card container used across the app.
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
