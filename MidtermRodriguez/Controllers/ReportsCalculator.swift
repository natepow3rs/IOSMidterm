//
//  ReportsCalculator.swift
//  InvoiceManager
//
//  CONTROLLER: turns invoices and payments into the figures on the
//  Reports screen. "Billed" counts invoices that were sent or paid
//  (drafts aren't bills yet), by issue date. "Collected" counts payments,
//  by the date the money arrived.
//

import Foundation

enum ReportsCalculator {

    static func summary(
        for period: ReportPeriod,
        invoices: [Invoice],
        payments: [Payment],
        clients: [Client],
        asOf now: Date = Date()
    ) -> ReportSummary {
        let calendar = Calendar.current
        let start = periodStart(months: period.months, asOf: now)

        let billedInvoices = invoices.filter { $0.status != .draft && $0.issueDate >= start }
        let periodPayments = payments.filter { $0.date >= start }

        return ReportSummary(
            period: period,
            billed: TotalsCalculator.total(of: billedInvoices),
            collected: TotalsCalculator.sum(of: periodPayments),
            averageDaysToGetPaid: averageDaysToGetPaid(
                invoices: invoices, payments: payments, since: start, calendar: calendar
            ),
            months: monthlyAmounts(
                months: period.months, invoices: billedInvoices, payments: periodPayments,
                asOf: now, calendar: calendar
            ),
            topClients: topClients(invoices: billedInvoices, clients: clients),
            paymentMethods: paymentMethods(payments: periodPayments)
        )
    }

    // MARK: - Pieces

    /// The first day of the oldest month in the period.
    static func periodStart(months: Int, asOf now: Date) -> Date {
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return calendar.date(byAdding: .month, value: -(months - 1), to: thisMonth) ?? thisMonth
    }

    /// One entry per month, oldest first, including months with no activity.
    static func monthlyAmounts(
        months: Int,
        invoices: [Invoice],
        payments: [Payment],
        asOf now: Date,
        calendar: Calendar
    ) -> [MonthlyAmount] {
        let start = periodStart(months: months, asOf: now)

        return (0..<months).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: start),
                  let interval = calendar.dateInterval(of: .month, for: month)
            else { return nil }

            let billed = TotalsCalculator.total(of: invoices.filter { interval.contains($0.issueDate) })
            let collected = TotalsCalculator.sum(of: payments.filter { interval.contains($0.date) })
            return MonthlyAmount(month: interval.start, billed: billed, collected: collected)
        }
    }

    /// Clients ranked by amount billed, largest first.
    static func topClients(invoices: [Invoice], clients: [Client], limit: Int = 5) -> [ClientAmount] {
        let totals = Dictionary(grouping: invoices, by: \.clientID)
            .mapValues { TotalsCalculator.total(of: $0) }

        return totals
            .map { clientID, amount in
                ClientAmount(
                    clientID: clientID,
                    name: clients.first { $0.id == clientID }?.name ?? "Unknown client",
                    amount: amount
                )
            }
            .sorted { $0.amount > $1.amount }
            .prefix(limit)
            .map { $0 }
    }

    /// Money received per payment method, largest first.
    static func paymentMethods(payments: [Payment]) -> [MethodAmount] {
        Dictionary(grouping: payments, by: \.method)
            .map { method, group in MethodAmount(method: method, amount: TotalsCalculator.sum(of: group)) }
            .sorted { $0.amount > $1.amount }
    }

    /// For invoices fully paid during the period: the average number of
    /// days from issue date to the final payment. Nil when there are none.
    static func averageDaysToGetPaid(
        invoices: [Invoice],
        payments: [Payment],
        since start: Date,
        calendar: Calendar
    ) -> Int? {
        let paymentsByInvoice = Dictionary(grouping: payments, by: \.invoiceID)

        let durations: [Int] = invoices.compactMap { invoice in
            guard invoice.status == .paid,
                  let finalPayment = paymentsByInvoice[invoice.id]?.map(\.date).max(),
                  finalPayment >= start
            else { return nil }

            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: invoice.issueDate),
                to: calendar.startOfDay(for: finalPayment)
            ).day ?? 0
            return max(0, days)
        }

        guard !durations.isEmpty else { return nil }
        return Int((Double(durations.reduce(0, +)) / Double(durations.count)).rounded())
    }
}
