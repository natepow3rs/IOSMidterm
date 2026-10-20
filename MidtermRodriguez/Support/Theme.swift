//
//  Theme.swift
//  InvoiceManager
//
//  Design tokens shared by every screen: colours, money typography,
//  corner radii and spacing. Colours live in Assets.xcassets so they
//  adapt to Light and Dark Mode automatically.
//
//  Visual direction: a bookkeeper's ledger. Ledger green is the brand
//  and means "settled"; blue means "waiting on the client"; amber means
//  "owed"; red is reserved for overdue money only.
//

import SwiftUI

enum Theme {

    // MARK: - Colours

    /// Ledger green. Also the app tint and the colour of paid invoices.
    static let brand = Color.accentColor
    static let sent = Color("StatusSent")
    static let owed = Color("AmountOwed")
    static let overdue = Color("StatusOverdue")
    static let draft = Color.gray

    /// Fixed (non-adaptive) brand colour for printed documents.
    static let brandPrint = Color(red: 0.118, green: 0.420, blue: 0.322)

    /// Palette for client avatars. A client always gets the same colour.
    static let avatarPalette: [Color] = [
        Color(red: 0.118, green: 0.420, blue: 0.322),
        Color(red: 0.145, green: 0.388, blue: 0.788),
        Color(red: 0.718, green: 0.475, blue: 0.122),
        Color(red: 0.533, green: 0.271, blue: 0.639),
        Color(red: 0.176, green: 0.522, blue: 0.584),
        Color(red: 0.678, green: 0.282, blue: 0.341)
    ]

    static func avatarColor(for id: UUID) -> Color {
        // Summing the characters is stable across launches (unlike hashValue).
        let sum = id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let index = sum % avatarPalette.count
        return avatarPalette[index]
    }

    // MARK: - Money typography

    /// Large figure for the one headline amount on a screen.
    static func heroAmountFont(size: CGFloat = 40) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Amounts inside rows and summaries.
    static let rowAmountFont = Font.system(.subheadline, design: .rounded).weight(.semibold)

    // MARK: - Shape and spacing

    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 10
    static let screenPadding: CGFloat = 16
}
