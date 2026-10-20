//
//  OverviewView.swift
//  InvoiceManager
//
//  SCREEN 2: answers "who owes me, and what needs chasing?"
//  A headline of money owed with a collection bar, the overdue
//  invoices that need attention, and the most recent invoices.
//  When nothing is saved yet it shows how to get started instead.
//

import SwiftUI

struct OverviewView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var invoiceDraft: Invoice?
    @State private var isPresentingClientForm = false

    var body: some View {
        Group {
            if store.isEmpty {
                gettingStarted
            } else {
                dashboard
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(greetingTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        invoiceDraft = store.makeDraftInvoice()
                    } label: {
                        Label("New invoice", systemImage: "doc.badge.plus")
                    }
                    .disabled(store.clients.isEmpty)

                    Button {
                        isPresentingClientForm = true
                    } label: {
                        Label("New client", systemImage: "person.badge.plus")
                    }
                } label: {
                    Label("Create", systemImage: "plus")
                }
            }
        }
        .sheet(item: $invoiceDraft) { draft in
            NavigationStack {
                InvoiceFormView(draft: draft, isNew: true)
            }
        }
        .sheet(isPresented: $isPresentingClientForm) {
            NavigationStack {
                ClientFormView(draft: Client(name: ""), isNew: true)
            }
        }
    }

    // MARK: - Dashboard

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headline
                if !store.overdueInvoices.isEmpty {
                    attentionSection
                }
                recentSection
            }
            .padding(Theme.screenPadding)
        }
    }

    /// The one bold element on the screen: how much clients owe.
    private var headline: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Clients owe you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(store.receivableTotal.currencyText)
                    .font(Theme.heroAmountFont())
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }

            CollectionBarView(
                collected: store.collectedTotal,
                owed: store.receivableTotal - store.overdueTotal,
                overdue: store.overdueTotal
            )

            HStack(alignment: .top, spacing: 20) {
                legendItem("Collected", store.collectedTotal, color: Theme.brand)
                legendItem("Not yet due", store.receivableTotal - store.overdueTotal, color: Theme.owed)
                legendItem("Overdue", store.overdueTotal, color: Theme.overdue)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        )
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                "Needs attention",
                detail: "\(store.overdueInvoices.count) overdue"
            )
            invoiceGroup(store.overdueInvoices)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Recent invoices", detail: nil)

            if store.recentInvoices.isEmpty {
                Text("Invoices you create will appear here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    )
            } else {
                invoiceGroup(store.recentInvoices)
            }
        }
    }

    // MARK: - Getting started

    private var gettingStarted: some View {
        ContentUnavailableView {
            Label("Start with your first client", systemImage: "person.crop.rectangle.stack")
        } description: {
            Text("Invoices are always issued to a client. Add one, then create an invoice for them. You can also try the app with sample data.")
        } actions: {
            Button("Add a client") { isPresentingClientForm = true }
                .buttonStyle(.borderedProminent)

            Button("Load sample data") { store.loadSampleData() }
        }
    }

    // MARK: - Building blocks

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private func sectionHeader(_ title: String, detail: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.overdue)
            }
        }
    }

    private func legendItem(_ title: String, _ amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(amount.currencyText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func invoiceGroup(_ invoices: [Invoice]) -> some View {
        VStack(spacing: 0) {
            ForEach(invoices) { invoice in
                NavigationLink {
                    InvoiceDetailView(invoiceID: invoice.id)
                } label: {
                    HStack(spacing: 10) {
                        InvoiceRowView(
                            invoice: invoice,
                            clientName: store.clientName(for: invoice.clientID)
                        )
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if invoice.id != invoices.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        )
    }
}

#Preview {
    NavigationStack {
        OverviewView()
    }
    .environmentObject(InvoiceStore.preview)
}
