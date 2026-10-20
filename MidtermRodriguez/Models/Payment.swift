//
//  Payment.swift
//  InvoiceManager
//
//  MODEL: money received against one invoice. An invoice can have
//  several payments, so partial payments are supported.
//

import Foundation

struct Payment: Identifiable, Codable, Hashable {

    let id: UUID
    var invoiceID: Invoice.ID
    var amount: Decimal
    var date: Date
    var method: PaymentMethod

    /// Optional transaction or check number, e.g. a GCash reference.
    var reference: String

    init(
        id: UUID = UUID(),
        invoiceID: Invoice.ID,
        amount: Decimal,
        date: Date = Date(),
        method: PaymentMethod = .cash,
        reference: String = ""
    ) {
        self.id = id
        self.invoiceID = invoiceID
        self.amount = amount
        self.date = date
        self.method = method
        self.reference = reference
    }

    /// A payment must be for a positive amount.
    var isValid: Bool {
        amount > 0
    }
}
