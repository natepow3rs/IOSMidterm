//
//  Decimal+Currency.swift
//  InvoiceManager
//
//  Formatting helpers. Kept out of the views so that every screen
//  displays money in exactly the same way.
//

import Foundation

extension Decimal {

    /// The amount rendered with the app's currency symbol, e.g. "₱12,500.00".
    var currencyText: String {
        formatted(.currency(code: AppConfiguration.currencyCode))
    }

    /// The amount rendered as a percentage, e.g. "12%".
    var percentText: String {
        formatted(.percent.precision(.fractionLength(0...2)))
    }
}

extension Date {

    /// A short, readable date such as "Sep 9, 2026".
    var shortDateText: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
