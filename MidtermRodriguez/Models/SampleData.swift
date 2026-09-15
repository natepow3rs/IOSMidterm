//
//  SampleData.swift
//  InvoiceManager
//
//  Seed data used on first launch and by the Xcode previews.
//  Whole-peso literals are used so the Decimal values stay exact.
//

import Foundation

enum SampleData {

    static let clients: [Client] = [
        Client(
            id: clientIDs[0],
            name: "Santex Building Company",
            contactPerson: "Javier Santos",
            email: "javier@santexbuilding.com",
            address: "142 Aurora Blvd, Quezon City"
        ),
        Client(
            id: clientIDs[1],
            name: "Northwind Logistics",
            contactPerson: "Mia Delgado",
            email: "accounts@northwindlogistics.ph",
            address: "8 Bagtikan St, Makati City"
        ),
        Client(
            id: clientIDs[2],
            name: "Bayanihan Coffee Roasters",
            contactPerson: "Paolo Cruz",
            email: "paolo@bayanihanroasters.ph",
            address: "27 Real St, Bacoor, Cavite"
        )
    ]

    static let invoices: [Invoice] = [
        Invoice(
            number: "INV-2026-001",
            clientID: clientIDs[0],
            issueDate: date(daysAgo: 40),
            dueDate: date(daysAgo: 10),
            status: .sent,
            lineItems: [
                LineItem(details: "Monthly bookkeeping", quantity: 1, unitPrice: 18000),
                LineItem(details: "Payroll processing", quantity: 12, unitPrice: 450)
            ],
            notes: "Payable to ALS Rodriguez Accounting Services."
        ),
        Invoice(
            number: "INV-2026-002",
            clientID: clientIDs[1],
            issueDate: date(daysAgo: 18),
            dueDate: date(daysAgo: -12),
            status: .sent,
            lineItems: [
                LineItem(details: "Accounts payable clean-up", quantity: 20, unitPrice: 1200)
            ]
        ),
        Invoice(
            number: "INV-2026-003",
            clientID: clientIDs[2],
            issueDate: date(daysAgo: 55),
            dueDate: date(daysAgo: 25),
            status: .paid,
            lineItems: [
                LineItem(details: "Year-end financial statements", quantity: 1, unitPrice: 32000),
                LineItem(details: "BIR filing assistance", quantity: 3, unitPrice: 2500)
            ],
            notes: "Settled via bank transfer."
        ),
        Invoice(
            number: "INV-2026-004",
            clientID: clientIDs[0],
            issueDate: date(daysAgo: 2),
            dueDate: date(daysAgo: -28),
            status: .draft,
            lineItems: [
                LineItem(details: "Cash flow forecast build", quantity: 1, unitPrice: 15000)
            ]
        )
    ]

    // MARK: - Helpers

    private static let clientIDs: [UUID] = [UUID(), UUID(), UUID()]

    private static func date(daysAgo days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

extension InvoiceStore {

    /// A ready-made store for Xcode previews.
    static var preview: InvoiceStore {
        InvoiceStore(clients: SampleData.clients, invoices: SampleData.invoices)
    }
}
