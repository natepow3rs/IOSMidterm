//
//  Invoice.swift
//  InvoiceManager
//
//  MODEL: a billing document issued to one client.
//  Money arithmetic lives in TotalsCalculator, not here.
//

import Foundation

struct Invoice: Identifiable, Codable, Hashable {

    let id: UUID
    var number: String
    var clientID: Client.ID
    var issueDate: Date
    var dueDate: Date
    var status: InvoiceStatus
    var vatRate: Decimal
    var lineItems: [LineItem]
    var notes: String

    init(
        id: UUID = UUID(),
        number: String,
        clientID: Client.ID,
        issueDate: Date = Date(),
        dueDate: Date = Date(),
        status: InvoiceStatus = .draft,
        vatRate: Decimal = AppConfiguration.defaultVATRate,
        lineItems: [LineItem] = [],
        notes: String = ""
    ) {
        self.id = id
        self.number = number
        self.clientID = clientID
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.status = status
        self.vatRate = vatRate
        self.lineItems = lineItems
        self.notes = notes
    }

    /// True when payment is past due and the invoice has not been settled.
    func isOverdue(asOf date: Date = Date()) -> Bool {
        status.isOutstanding && dueDate < date
    }

    /// An invoice is only ready to save once it has a number and at least
    /// one described line item.
    var isValid: Bool {
        !number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && lineItems.contains { $0.isValid }
    }

    /// Number of days remaining before the due date (negative when overdue).
    func daysUntilDue(asOf date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
