//
//  InvoiceListView.swift
//  InvoiceManager
//
//  SCREEN 3: every invoice, with filter chips (including Overdue),
//  search, swipe to mark as paid, and swipe to delete with confirmation.
//

import SwiftUI

struct InvoiceListView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var filter: InvoiceFilter = .all
    @State private var searchText = ""
    @State private var invoiceDraft: Invoice?
    @State private var invoicePendingDeletion: Invoice?

    /// Searching happens here, in the view, because the search text is
    /// presentation state. The filtered data still comes from the controller.
    private var displayedInvoices: [Invoice] {
        let filtered = store.invoices(matching: filter)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return filtered }

        return filtered.filter { invoice in
            invoice.number.localizedCaseInsensitiveContains(query)
                || store.clientName(for: invoice.clientID).localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                filterChips
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if !displayedInvoices.isEmpty {
                Section {
                    ForEach(displayedInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoiceID: invoice.id)
                        } label: {
                            InvoiceRowView(
                                invoice: invoice,
                                clientName: store.clientName(for: invoice.clientID)
                            )
                        }
                        .swipeActions(edge: .leading) {
                            statusSwipeAction(for: invoice)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                invoicePendingDeletion = invoice
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(headerText)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search by client or invoice number")
        .navigationTitle("Invoices")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    invoiceDraft = store.makeDraftInvoice()
                } label: {
                    Label("New invoice", systemImage: "plus")
                }
                .disabled(store.clients.isEmpty)
            }
        }
        .overlay {
            if displayedInvoices.isEmpty {
                emptyState
            }
        }
        .sheet(item: $invoiceDraft) { draft in
            NavigationStack {
                InvoiceFormView(draft: draft, isNew: true)
            }
        }
        .confirmationDialog(
            "Delete this invoice?",
            isPresented: Binding(
                get: { invoicePendingDeletion != nil },
                set: { if !$0 { invoicePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: invoicePendingDeletion
        ) { invoice in
            Button("Delete \(invoice.number)", role: .destructive) {
                store.deleteInvoice(withID: invoice.id)
            }
        } message: { invoice in
            Text("\(invoice.number) for \(store.clientName(for: invoice.clientID)) will be permanently removed.")
        }
        .sensoryFeedback(.success, trigger: store.collectedTotal)
    }

    // MARK: - Subviews

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InvoiceFilter.allCases) { option in
                    FilterChipView(
                        title: option.title,
                        count: store.count(matching: option),
                        isSelected: filter == option,
                        tint: option == .overdue ? Theme.overdue : Theme.brand
                    ) {
                        withAnimation(.snappy) { filter = option }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Leading swipe moves the invoice one step forward: send a draft,
    /// or record payment for a sent invoice.
    @ViewBuilder
    private func statusSwipeAction(for invoice: Invoice) -> some View {
        switch invoice.status {
        case .draft:
            Button {
                store.setStatus(.sent, forInvoiceWithID: invoice.id)
            } label: {
                Label("Mark as sent", systemImage: "paperplane")
            }
            .tint(Theme.sent)
        case .sent:
            Button {
                store.setStatus(.paid, forInvoiceWithID: invoice.id)
            } label: {
                Label("Mark as paid", systemImage: "checkmark.seal")
            }
            .tint(Theme.brand)
        case .paid:
            EmptyView()
        }
    }

    private var headerText: String {
        let count = displayedInvoices.count
        let total = TotalsCalculator.total(of: displayedInvoices)
        return "\(count) invoice\(count == 1 ? "" : "s"), \(total.currencyText)"
    }

    @ViewBuilder
    private var emptyState: some View {
        if store.clients.isEmpty {
            ContentUnavailableView(
                "Add a client first",
                systemImage: "person.crop.circle.badge.plus",
                description: Text("Invoices are always issued to a client. Add one on the Clients tab.")
            )
        } else if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if filter == .all {
            ContentUnavailableView {
                Label("No invoices yet", systemImage: "doc.text")
            } description: {
                Text("Create your first invoice to start tracking what clients owe you.")
            } actions: {
                Button("New invoice") { invoiceDraft = store.makeDraftInvoice() }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView(
                emptyTitle(for: filter),
                systemImage: filter == .overdue ? "checkmark.circle" : "tray",
                description: Text(filter == .overdue
                                  ? "Every sent invoice is still within its due date."
                                  : "Invoices will show here when they match this filter.")
            )
        }
    }

    private func emptyTitle(for filter: InvoiceFilter) -> String {
        switch filter {
        case .all:     return "No invoices yet"
        case .draft:   return "No drafts"
        case .sent:    return "Nothing awaiting payment"
        case .overdue: return "Nothing overdue"
        case .paid:    return "No paid invoices yet"
        }
    }
}

#Preview {
    NavigationStack {
        InvoiceListView()
    }
    .environmentObject(InvoiceStore.preview)
}
