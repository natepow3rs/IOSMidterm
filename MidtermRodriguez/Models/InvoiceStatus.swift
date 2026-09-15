//
//  InvoiceStatus.swift
//  InvoiceManager
//
//  MODEL: the lifecycle of an invoice.
//  Colours are deliberately NOT defined here — those belong to the
//  view layer (see StatusBadgeView).
//

import Foundation

enum InvoiceStatus: String, Codable, CaseIterable, Identifiable {

    case draft
    case sent
    case paid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .sent:  return "Sent"
        case .paid:  return "Paid"
        }
    }

    var symbolName: String {
        switch self {
        case .draft: return "pencil.line"
        case .sent:  return "paperplane.fill"
        case .paid:  return "checkmark.seal.fill"
        }
    }

    /// Amounts in these states are still owed to the business.
    var isOutstanding: Bool {
        self != .paid
    }
}
