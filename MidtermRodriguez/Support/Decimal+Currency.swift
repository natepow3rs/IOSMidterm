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

    /// The amount as a Double, for charts.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// A short amount for chart axes, e.g. "₱25K".
    var compactCurrencyText: String {
        "₱" + doubleValue.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
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
