//
//  SampleData.swift
//  InvoiceManager
//
//  Demo data. It is NOT loaded automatically: the app starts empty and
//  only uses this when the user taps "Load sample data" in Settings,
//  and for Xcode previews.
//  Whole-peso literals are used so the Decimal values stay exact.
//

import Foundation

enum SampleData {

    /// The demo issuing business.
    static let businessProfile = BusinessProfile(
        name: "ALS Rodriguez Accounting Services"
    )

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

    /// Four current invoices (one overdue and part-paid, two awaiting
    /// payment, one draft) plus five older invoices that were paid, so the
    /// Reports charts have a few months of history.
    static let invoices: [Invoice] = [
        Invoice(
            id: invoiceIDs[0],
            number: number(6),
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
            id: invoiceIDs[1],
            number: number(7),
            clientID: clientIDs[1],
            issueDate: date(daysAgo: 18),
            dueDate: date(daysAgo: -12),
            status: .sent,
            lineItems: [
                LineItem(details: "Accounts payable clean-up", quantity: 20, unitPrice: 1200)
            ]
        ),
        Invoice(
            id: invoiceIDs[2],
            number: number(8),
            clientID: clientIDs[2],
            issueDate: date(daysAgo: 10),
            dueDate: date(daysAgo: -20),
            status: .sent,
            lineItems: [
                LineItem(details: "Inventory count support", quantity: 2, unitPrice: 3500)
            ]
        ),
        Invoice(
            id: invoiceIDs[3],
            number: number(9),
            clientID: clientIDs[0],
            issueDate: date(daysAgo: 2),
            dueDate: date(daysAgo: -28),
            status: .draft,
            lineItems: [
                LineItem(details: "Cash flow forecast build", quantity: 1, unitPrice: 15000)
            ]
        ),
        Invoice(
            id: invoiceIDs[4],
            number: number(1),
            clientID: clientIDs[0],
            issueDate: date(daysAgo: 170),
            dueDate: date(daysAgo: 140),
            status: .sent,
            lineItems: [
                LineItem(details: "Monthly bookkeeping", quantity: 1, unitPrice: 18000)
            ]
        ),
        Invoice(
            id: invoiceIDs[5],
            number: number(2),
            clientID: clientIDs[1],
            issueDate: date(daysAgo: 140),
            dueDate: date(daysAgo: 110),
            status: .sent,
            lineItems: [
                LineItem(details: "Monthly bookkeeping", quantity: 1, unitPrice: 15000),
                LineItem(details: "Payroll processing", quantity: 10, unitPrice: 450)
            ]
        ),
        Invoice(
            id: invoiceIDs[6],
            number: number(3),
            clientID: clientIDs[2],
            issueDate: date(daysAgo: 110),
            dueDate: date(daysAgo: 80),
            status: .sent,
            lineItems: [
                LineItem(details: "Year-end financial statements", quantity: 1, unitPrice: 32000),
                LineItem(details: "BIR filing assistance", quantity: 3, unitPrice: 2500)
            ]
        ),
        Invoice(
            id: invoiceIDs[7],
            number: number(4),
            clientID: clientIDs[0],
            issueDate: date(daysAgo: 80),
            dueDate: date(daysAgo: 50),
            status: .sent,
            lineItems: [
                LineItem(details: "Monthly bookkeeping", quantity: 1, unitPrice: 18000),
                LineItem(details: "Payroll processing", quantity: 12, unitPrice: 450)
            ]
        ),
        Invoice(
            id: invoiceIDs[8],
            number: number(5),
            clientID: clientIDs[1],
            issueDate: date(daysAgo: 55),
            dueDate: date(daysAgo: 25),
            status: .sent,
            lineItems: [
                LineItem(details: "Quarterly tax review", quantity: 1, unitPrice: 12000)
            ]
        )
    ]

    /// One part payment on the overdue invoice, and full payments that
    /// settle the five older invoices (InvoiceStore marks them Paid).
    static let payments: [Payment] = [
        Payment(invoiceID: invoiceIDs[0], amount: 10000, date: date(daysAgo: 15),
                method: .gcash, reference: "GC-7741203"),
        fullPayment(of: 4, daysAgo: 152, method: .bankTransfer, reference: "BDO-118204"),
        fullPayment(of: 5, daysAgo: 118, method: .gcash, reference: "GC-5520918"),
        fullPayment(of: 6, daysAgo: 85, method: .bankTransfer, reference: "BPI-660137"),
        fullPayment(of: 7, daysAgo: 58, method: .cash),
        fullPayment(of: 8, daysAgo: 30, method: .maya, reference: "MY-3309471")
    ]

    // MARK: - Helpers

    private static let clientIDs: [UUID] = [UUID(), UUID(), UUID()]
    private static let invoiceIDs: [UUID] = (0..<9).map { _ in UUID() }

    private static func number(_ sequence: Int) -> String {
        let year = Calendar.current.component(.year, from: Date())
        return String(format: "INV-%d-%03d", year, sequence)
    }

    private static func fullPayment(
        of invoiceIndex: Int,
        daysAgo days: Int,
        method: PaymentMethod,
        reference: String = ""
    ) -> Payment {
        let invoice = invoices[invoiceIndex]
        return Payment(
            invoiceID: invoice.id,
            amount: TotalsCalculator.total(of: invoice),
            date: date(daysAgo: days),
            method: method,
            reference: reference
        )
    }

    private static func date(daysAgo days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

extension InvoiceStore {

    /// A ready-made store for Xcode previews, backed by a throw-away
    /// in-memory database filled with the demo data.
    static var preview: InvoiceStore {
        let store = InvoiceStore(container: InvoiceDatabase.makeInMemoryContainer())
        store.loadSampleData()
        return store
    }
}
