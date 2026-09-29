//
//  Invoice.swift
//  InvoiceManager
//
//  MODEL: a billing document issued to one client.
//  Now a SwiftData model for persistent storage.
//  Money arithmetic lives in TotalsCalculator, not here.
//

import Foundation
import SwiftData

@Model
final class Invoice {

    var id: UUID
    var number: String
    var issueDate: Date
    var dueDate: Date
    var statusRawValue: String  // Store InvoiceStatus as raw value
    var vatRate: Decimal
    var notes: String
    
    // Store clientID temporarily for initialization
    private var temporaryClientID: UUID?
    
    // Relationship to client
    var client: Client?
    
    // Relationship to line items
    @Relationship(deleteRule: .cascade)
    var lineItems: [LineItem]

    init(
        id: UUID = UUID(),
        number: String,
        clientID: UUID,
        issueDate: Date = Date(),
        dueDate: Date = Date(),
        status: InvoiceStatus = .draft,
        vatRate: Decimal = AppConfiguration.defaultVATRate,
        lineItems: [LineItem] = [],
        notes: String = ""
    ) {
        self.id = id
        self.number = number
        self.temporaryClientID = clientID
        self.client = nil  // Will be set later through relationship
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.statusRawValue = status.rawValue
        self.vatRate = vatRate
        self.lineItems = lineItems
        self.notes = notes
    }
    
    // Computed property for status
    var status: InvoiceStatus {
        get { InvoiceStatus(rawValue: statusRawValue) ?? .draft }
        set { statusRawValue = newValue.rawValue }
    }
    
    // Helper to get/set clientID for backward compatibility
    var clientID: UUID {
        get { client?.id ?? temporaryClientID ?? UUID() }
        set { 
            temporaryClientID = newValue
            // The actual client relationship should be set separately via the client property
        }
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
