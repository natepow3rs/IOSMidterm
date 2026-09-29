//
//  OverviewView.swift
//  InvoiceManager
//
//  SCREEN 2: dashboard showing money owed, money collected,
//  a breakdown by status, and the most recent invoices.
//

import SwiftUI
import SwiftData

struct OverviewView: View {

    @Query(sort: \Invoice.issueDate, order: .reverse) private var allInvoices: [Invoice]
    @Query private var allClients: [Client]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summarySection
                statusSection
                recentSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Overview")
    }
    
    // MARK: - Computed Properties
    
    private var outstandingTotal: Decimal {
        allInvoices
            .filter { $0.status.isOutstanding }
            .reduce(0) { $0 + TotalsCalculator.calculate(for: $1).grandTotal }
    }
    
    private var collectedTotal: Decimal {
        allInvoices
            .filter { $0.status == .paid }
            .reduce(0) { $0 + TotalsCalculator.calculate(for: $1).grandTotal }
    }
    
    private var overdueInvoices: [Invoice] {
        allInvoices.filter { $0.isOverdue() }
    }
    
    private var recentInvoices: [Invoice] {
        Array(allInvoices.prefix(5))
    }
    
    private func count(of status: InvoiceStatus) -> Int {
        allInvoices.filter { $0.status == status }.count
    }
    
    private func clientName(for clientID: UUID) -> String {
        allClients.first { $0.id == clientID }?.name ?? "Unknown"
    }

    // MARK: - Sections

    private var summarySection: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryTileView(
                title: "Outstanding",
                value: outstandingTotal.currencyText,
                symbolName: "hourglass",
                tint: .orange
            )
            SummaryTileView(
                title: "Collected",
                value: collectedTotal.currencyText,
                symbolName: "checkmark.seal",
                tint: .green
            )
            SummaryTileView(
                title: "Active clients",
                value: "\(allClients.count)",
                symbolName: "person.2",
                tint: .blue
            )
            SummaryTileView(
                title: "Overdue",
                value: "\(overdueInvoices.count)",
                symbolName: "exclamationmark.triangle",
                tint: .red
            )
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By status")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(InvoiceStatus.allCases.enumerated()), id: \.element.id) { index, status in
                    HStack {
                        StatusBadgeView(status: status)
                        Spacer()
                        Text("\(count(of: status))")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)

                    if index < InvoiceStatus.allCases.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent invoices")
                .font(.headline)

            if recentInvoices.isEmpty {
                Text("No invoices yet. Create one from the Invoices tab.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(recentInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoiceID: invoice.id)
                        } label: {
                            InvoiceRowView(
                                invoice: invoice,
                                clientName: clientName(for: invoice.clientID)
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        if invoice.id != recentInvoices.last?.id {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

#Preview {
    NavigationStack {
        OverviewView()
    }
    .modelContainer(for: [Invoice.self, Client.self, LineItem.self], inMemory: true)
}
