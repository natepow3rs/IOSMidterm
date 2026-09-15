//
//  AppConfiguration.swift
//  InvoiceManager
//
//  Single place for app-wide constants so that no value is hard-coded
//  inside a view.
//

import Foundation

enum AppConfiguration {

    /// ISO 4217 code used for every amount shown in the app.
    static let currencyCode = "PHP"

    /// Default value-added tax rate applied to new invoices (12%).
    static let defaultVATRate = Decimal(12) / Decimal(100)

    /// Number of days added to the issue date to produce a default due date.
    static let defaultPaymentTermsInDays = 30

    /// Number of invoices shown in the "Recent activity" list on the overview.
    static let recentInvoiceLimit = 5
}
