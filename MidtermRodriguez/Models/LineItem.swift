//
//  LineItem.swift
//  InvoiceManager
//
//  MODEL: a single billable row inside an invoice.
//

import Foundation

struct LineItem: Identifiable, Codable, Hashable {

    let id: UUID
    var details: String
    var quantity: Decimal
    var unitPrice: Decimal

    init(
        id: UUID = UUID(),
        details: String = "",
        quantity: Decimal = 1,
        unitPrice: Decimal = 0
    ) {
        self.id = id
        self.details = details
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    /// Quantity multiplied by unit price.
    var amount: Decimal {
        quantity * unitPrice
    }

    /// A row is only counted once it has a description.
    var isValid: Bool {
        !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
