//
//  PaymentRecord.swift
//  InvoiceManager
//
//  PERSISTENCE: how a Payment is stored in the SwiftData database.
//  It points to its invoice by ID; InvoiceStore removes payments
//  whenever their invoice is deleted.
//

import Foundation
import SwiftData

@Model
final class PaymentRecord {

    @Attribute(.unique) var uuid: UUID
    var invoiceID: UUID
    var amount: Decimal
    var date: Date
    var methodRawValue: String
    var reference: String

    init(_ payment: Payment) {
        self.uuid = payment.id
        self.invoiceID = payment.invoiceID
        self.amount = payment.amount
        self.date = payment.date
        self.methodRawValue = payment.method.rawValue
        self.reference = payment.reference
    }

    /// The stored record as the app's model struct.
    var value: Payment {
        Payment(
            id: uuid,
            invoiceID: invoiceID,
            amount: amount,
            date: date,
            method: PaymentMethod(rawValue: methodRawValue) ?? .other,
            reference: reference
        )
    }
}
