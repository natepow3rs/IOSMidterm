//
//  InvoiceRecord.swift
//  InvoiceManager
//
//  PERSISTENCE: how an Invoice is stored in the SwiftData database.
//  Line items are stored as related LineItemRecord rows and are deleted
//  automatically when their invoice is deleted (cascade rule).
//

import Foundation
import SwiftData

@Model
final class InvoiceRecord {

    @Attribute(.unique) var uuid: UUID
    var number: String
    var clientID: UUID
    var issueDate: Date
    var dueDate: Date
    var statusRawValue: String
    var vatRate: Decimal
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \LineItemRecord.invoice)
    var lineItems: [LineItemRecord] = []

    /// Creates the record without line items. Call `replaceLineItems(with:in:)`
    /// after inserting it into a context.
    init(_ invoice: Invoice) {
        self.uuid = invoice.id
        self.number = invoice.number
        self.clientID = invoice.clientID
        self.issueDate = invoice.issueDate
        self.dueDate = invoice.dueDate
        self.statusRawValue = invoice.status.rawValue
        self.vatRate = invoice.vatRate
        self.notes = invoice.notes
    }

    /// Copies edited values from the struct into the stored record
    /// (everything except line items).
    func apply(_ invoice: Invoice) {
        number = invoice.number
        clientID = invoice.clientID
        issueDate = invoice.issueDate
        dueDate = invoice.dueDate
        statusRawValue = invoice.status.rawValue
        vatRate = invoice.vatRate
        notes = invoice.notes
    }

    /// Deletes the stored line items and stores the given ones in their place,
    /// keeping their on-screen order.
    func replaceLineItems(with items: [LineItem], in context: ModelContext) {
        for record in lineItems {
            context.delete(record)
        }

        var newRecords: [LineItemRecord] = []
        for (position, item) in items.enumerated() {
            let record = LineItemRecord(item, position: position)
            context.insert(record)
            newRecords.append(record)
        }
        lineItems = newRecords
    }

    /// The stored record as the app's model struct.
    var value: Invoice {
        Invoice(
            id: uuid,
            number: number,
            clientID: clientID,
            issueDate: issueDate,
            dueDate: dueDate,
            status: InvoiceStatus(rawValue: statusRawValue) ?? .draft,
            vatRate: vatRate,
            lineItems: lineItems
                .sorted { $0.position < $1.position }
                .map(\.value),
            notes: notes
        )
    }
}
