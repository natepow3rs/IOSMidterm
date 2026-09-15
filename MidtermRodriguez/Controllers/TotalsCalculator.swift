//
//  TotalsCalculator.swift
//  InvoiceManager
//
//  CONTROLLER: every peso figure in the app is produced here.
//  Declared as an enum so that it can never be instantiated.
//

import Foundation

enum TotalsCalculator {

    /// Sum of all line item amounts, rounded to two decimal places.
    static func subtotal(of items: [LineItem]) -> Decimal {
        rounded(items.reduce(Decimal.zero) { $0 + $1.amount })
    }

    static func subtotal(of invoice: Invoice) -> Decimal {
        subtotal(of: invoice.lineItems)
    }

    /// Value-added tax charged on the subtotal.
    static func vat(of invoice: Invoice) -> Decimal {
        rounded(subtotal(of: invoice) * invoice.vatRate)
    }

    /// Subtotal plus VAT — the amount the client actually pays.
    static func total(of invoice: Invoice) -> Decimal {
        subtotal(of: invoice) + vat(of: invoice)
    }

    /// Combined total of a group of invoices.
    static func total(of invoices: [Invoice]) -> Decimal {
        invoices.reduce(Decimal.zero) { $0 + total(of: $1) }
    }

    /// Commercial rounding to a fixed number of decimal places.
    static func rounded(_ value: Decimal, scale: Int = 2) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }
}
