//
//  InvoiceListView.swift
//  InvoiceManager
//
//  SCREEN 3: every invoice, with a status filter, search,
//  swipe-to-delete and a button that opens the create form.
//

import SwiftUI

struct InvoiceListView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var selectedStatus: InvoiceStatus?
    @State private var searchText = ""
    @State private var isPresentingForm = false

    /// Filtering happens here, in the view, because it is presentation
    /// state. The underlying data still comes from the controller.
    private var displayedInvoices: [Invoice] {
        let filtered = store.invoices(with: selectedStatus)
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
                Picker("Status", selection: $selectedStatus) {
                    Text("All").tag(InvoiceStatus?.none)
                    ForEach(InvoiceStatus.allCases) { status in
                        Text(status.displayName).tag(InvoiceStatus?.some(status))
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }

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
                }
                .onDelete(perform: deleteInvoices)
            } header: {
                Text(headerText)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search number or client")
        .navigationTitle("Invoices")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingForm = true
                } label: {
                    Label("New invoice", systemImage: "plus")
                }
                .disabled(store.clients.isEmpty)
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                InvoiceFormView(draft: store.makeDraftInvoice(), isNew: true)
            }
        }
        .overlay {
            if displayedInvoices.isEmpty {
                emptyState
            }
        }
    }

    // MARK: - Subviews

    private var headerText: String {
        let count = displayedInvoices.count
        let total = TotalsCalculator.total(of: displayedInvoices)
        return "\(count) invoice\(count == 1 ? "" : "s") · \(total.currencyText)"
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(store.clients.isEmpty ? "Add a client first" : "No invoices match this filter")
                .font(.headline)

            Text(store.clients.isEmpty
                 ? "Invoices are always issued to a client, so start on the Clients tab."
                 : "Try a different status or clear the search.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Actions

    /// Offsets refer to the *filtered* array, so they are mapped back to
    /// identifiers before anything is removed.
    private func deleteInvoices(at offsets: IndexSet) {
        let ids = offsets.map { displayedInvoices[$0].id }
        for id in ids {
            store.deleteInvoice(withID: id)
        }
    }
}

#Preview {
    NavigationStack {
        InvoiceListView()
    }
    .environmentObject(InvoiceStore.preview)
}
