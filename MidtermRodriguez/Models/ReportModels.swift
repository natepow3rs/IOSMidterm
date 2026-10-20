//
//  ReportModels.swift
//  InvoiceManager
//
//  MODEL: the figures shown on the Reports screen. They are produced by
//  ReportsCalculator and only read by the view.
//

import Foundation

/// How far back the report looks.
enum ReportPeriod: Int, CaseIterable, Identifiable {

    case threeMonths = 3
    case sixMonths = 6
    case twelveMonths = 12

    var id: Int { rawValue }
    var months: Int { rawValue }

    var title: String {
        "\(rawValue) months"
    }
}

/// Money billed and collected in one calendar month.
struct MonthlyAmount: Identifiable, Hashable {
    let month: Date
    let billed: Decimal
    let collected: Decimal

    var id: Date { month }
}

/// Amount billed to one client in the period.
struct ClientAmount: Identifiable, Hashable {
    let clientID: Client.ID
    let name: String
    let amount: Decimal

    var id: Client.ID { clientID }
}

/// Amount received through one payment method in the period.
struct MethodAmount: Identifiable, Hashable {
    let method: PaymentMethod
    let amount: Decimal

    var id: PaymentMethod { method }
}

/// Everything the Reports screen shows for one period.
struct ReportSummary {
    let period: ReportPeriod
    let billed: Decimal
    let collected: Decimal
    let averageDaysToGetPaid: Int?
    let months: [MonthlyAmount]
    let topClients: [ClientAmount]
    let paymentMethods: [MethodAmount]

    var hasActivity: Bool {
        billed > 0 || collected > 0
    }
}
