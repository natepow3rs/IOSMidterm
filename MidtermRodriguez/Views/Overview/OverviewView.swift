//
//  OverviewView.swift
//  InvoiceManager
//
//  SCREEN 2: dashboard showing money owed, money collected,
//  a breakdown by status, and the most recent invoices.
//

import SwiftUI

struct OverviewView: View {

    @EnvironmentObject private var store: InvoiceStore

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

    // MARK: - Sections

    private var summarySection: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryTileView(
                title: "Outstanding",
                value: store.outstandingTotal.currencyText,
                symbolName: "hourglass",
                tint: .orange
            )
            SummaryTileView(
                title: "Collected",
                value: store.collectedTotal.currencyText,
                symbolName: "checkmark.seal",
                tint: .green
            )
            SummaryTileView(
                title: "Active clients",
                value: "\(store.clients.count)",
                symbolName: "person.2",
                tint: .blue
            )
            SummaryTileView(
                title: "Overdue",
                value: "\(store.overdueInvoices.count)",
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
                        Text("\(store.count(of: status))")
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

            if store.recentInvoices.isEmpty {
                Text("No invoices yet. Create one from the Invoices tab.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(store.recentInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoiceID: invoice.id)
                        } label: {
                            InvoiceRowView(
                                invoice: invoice,
                                clientName: store.clientName(for: invoice.clientID)
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        if invoice.id != store.recentInvoices.last?.id {
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
    .environmentObject(InvoiceStore.preview)
}
