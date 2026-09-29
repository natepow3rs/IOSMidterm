//
//  InvoiceListView.swift
//  InvoiceManager
//
//  SCREEN 3: every invoice, with a status filter, search,
//  swipe-to-delete and a button that opens the create form.
//

import SwiftUI
import SwiftData

struct InvoiceListView: View {

    @Query(sort: \Invoice.issueDate, order: .reverse) private var allInvoices: [Invoice]
    @Query private var allClients: [Client]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedStatus: InvoiceStatus?
    @State private var searchText = ""
    @State private var isPresentingForm = false

    /// Filtering happens here, in the view, because it is presentation
    /// state. The underlying data still comes from SwiftData.
    private var displayedInvoices: [Invoice] {
        let filtered = selectedStatus == nil ? allInvoices : allInvoices.filter { $0.status == selectedStatus }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return filtered }

        return filtered.filter { invoice in
            invoice.number.localizedCaseInsensitiveContains(query)
                || clientName(for: invoice.clientID).localizedCaseInsensitiveContains(query)
        }
    }
    
    private func clientName(for clientID: UUID) -> String {
        allClients.first { $0.id == clientID }?.name ?? "Unknown"
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
                            clientName: clientName(for: invoice.clientID)
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
                .disabled(allClients.isEmpty)
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                InvoiceFormView(draft: makeDraftInvoice(), isNew: true)
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

            Text(allClients.isEmpty ? "Add a client first" : "No invoices match this filter")
                .font(.headline)

            Text(allClients.isEmpty
                 ? "Invoices are always issued to a client, so start on the Clients tab."
                 : "Try a different status or clear the search.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
    
    // MARK: - Helper Methods
    
    private func makeDraftInvoice() -> Invoice {
        let nextNumber = "INV-\(String(format: "%04d", allInvoices.count + 1))"
        let firstClient = allClients.first
        return Invoice(
            number: nextNumber,
            clientID: firstClient?.id ?? UUID(),
            issueDate: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            status: .draft,
            vatRate: AppConfiguration.defaultVATRate,
            lineItems: [],
            notes: ""
        )
    }

    // MARK: - Actions

    /// Offsets refer to the *filtered* array, so they are mapped back to
    /// identifiers before anything is removed.
    private func deleteInvoices(at offsets: IndexSet) {
        let invoicesToDelete = offsets.map { displayedInvoices[$0] }
        for invoice in invoicesToDelete {
            modelContext.delete(invoice)
        }
    }
}

#Preview {
    NavigationStack {
        InvoiceListView()
    }
    .modelContainer(for: [Invoice.self, Client.self, LineItem.self], inMemory: true)
}
