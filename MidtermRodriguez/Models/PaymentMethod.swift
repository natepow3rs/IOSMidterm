//
//  PaymentMethod.swift
//  InvoiceManager
//
//  MODEL: how a client paid. Covers the methods most used by
//  Philippine small businesses.
//

import Foundation

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {

    case cash
    case gcash
    case maya
    case bankTransfer
    case check
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash:         return "Cash"
        case .gcash:        return "GCash"
        case .maya:         return "Maya"
        case .bankTransfer: return "Bank transfer"
        case .check:        return "Check"
        case .other:        return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .cash:         return "banknote"
        case .gcash, .maya: return "iphone.gen3"
        case .bankTransfer: return "building.columns"
        case .check:        return "doc.text"
        case .other:        return "ellipsis.circle"
        }
    }

    /// Cash rarely has a reference number; the others usually do.
    var usesReference: Bool {
        self != .cash
    }
}
