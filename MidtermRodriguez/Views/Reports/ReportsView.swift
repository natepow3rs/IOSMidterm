//
//  ReportsView.swift
//  InvoiceManager
//
//  SCREEN 11: how the business is doing over the last 3, 6 or 12 months,
//  drawn with Swift Charts — billed vs collected each month, the clients
//  billed the most, and how clients pay.
//

import SwiftUI
import Charts

struct ReportsView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var period: ReportPeriod = .sixMonths

    /// All figures come from the controller; the view only draws them.
    private var report: ReportSummary {
        ReportsCalculator.summary(
            for: period,
            invoices: store.invoices,
            payments: store.payments,
            clients: store.clients
        )
    }

    var body: some View {
        let report = self.report

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("Period", selection: $period) {
                    ForEach(ReportPeriod.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if report.hasActivity {
                    keyFigures(report)
                    monthlyCard(report)
                    clientsCard(report)
                    methodsCard(report)
                } else {
                    ContentUnavailableView(
                        "Nothing to report yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Charts appear once you send invoices or record payments in this period.")
                    )
                    .padding(.top, 40)
                }
            }
            .padding(Theme.screenPadding)
            .animation(.snappy, value: period)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reports")
    }

    // MARK: - Key figures

    private func keyFigures(_ report: ReportSummary) -> some View {
        HStack(alignment: .top, spacing: 12) {
            figure("Collected", report.collected.currencyText, tint: Theme.brand)
            figure("Billed", report.billed.currencyText, tint: Theme.sent)
            figure(
                "Avg. days to get paid",
                report.averageDaysToGetPaid.map { "\($0)" } ?? "–",
                tint: .primary
            )
        }
    }

    private func figure(_ title: String, _ value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        )
    }

    // MARK: - Billed vs collected

    private func monthlyCard(_ report: ReportSummary) -> some View {
        card(title: "Billed and collected", subtitle: "By month") {
            Chart {
                ForEach(report.months) { month in
                    BarMark(
                        x: .value("Month", month.month, unit: .month),
                        y: .value("Amount", month.billed.doubleValue)
                    )
                    .foregroundStyle(by: .value("Type", "Billed"))
                    .position(by: .value("Type", "Billed"))

                    BarMark(
                        x: .value("Month", month.month, unit: .month),
                        y: .value("Amount", month.collected.doubleValue)
                    )
                    .foregroundStyle(by: .value("Type", "Collected"))
                    .position(by: .value("Type", "Collected"))
                }
            }
            .chartForegroundStyleScale([
                "Billed": Theme.sent,
                "Collected": Theme.brand
            ])
            .chartLegend(position: .top, alignment: .leading)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: monthLabelFormat, centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(Decimal(amount).compactCurrencyText)
                        }
                    }
                }
            }
            .frame(height: 220)
            .accessibilityLabel("Bar chart of amounts billed and collected each month")
        }
    }

    /// Single letters fit twelve months; three-letter names fit fewer.
    private var monthLabelFormat: Date.FormatStyle {
        period == .twelveMonths
            ? Date.FormatStyle.dateTime.month(.narrow)
            : Date.FormatStyle.dateTime.month(.abbreviated)
    }

    // MARK: - Top clients

    private func clientsCard(_ report: ReportSummary) -> some View {
        card(title: "Top clients", subtitle: "By amount billed") {
            if report.topClients.isEmpty {
                emptyNote("No invoices were sent in this period.")
            } else {
                Chart(report.topClients) { client in
                    BarMark(
                        x: .value("Billed", client.amount.doubleValue),
                        y: .value("Client", client.name)
                    )
                    .foregroundStyle(Theme.sent.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(client.amount.compactCurrencyText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(report.topClients.count) * 44)
            }
        }
    }

    // MARK: - Payment methods

    private func methodsCard(_ report: ReportSummary) -> some View {
        card(title: "How clients pay", subtitle: "Share of money collected") {
            if report.paymentMethods.isEmpty {
                emptyNote("No payments were recorded in this period.")
            } else {
                HStack(alignment: .center, spacing: 20) {
                    Chart(report.paymentMethods) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount.doubleValue),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .cornerRadius(3)
                        .foregroundStyle(by: .value("Method", item.method.displayName))
                    }
                    .chartLegend(.hidden)
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.paymentMethods) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.method.symbolName)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 18)
                                Text(item.method.displayName)
                                Spacer(minLength: 4)
                                Text(share(of: item.amount, in: report.collected))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Building blocks

    private func card<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        )
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func share(of amount: Decimal, in total: Decimal) -> String {
        guard total > 0 else { return "–" }
        return (amount / total).doubleValue.formatted(.percent.precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
    .environmentObject(InvoiceStore.preview)
}
