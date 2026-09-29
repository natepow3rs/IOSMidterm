//
//  ClientListView.swift
//  InvoiceManager
//
//  SCREEN 6: all clients, sorted by name, with search and a button
//  that opens the client form.
//

import SwiftUI
import SwiftData

struct ClientListView: View {

    @Query(sort: \Client.name) private var allClients: [Client]
    @Query private var allInvoices: [Invoice]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var isPresentingForm = false

    private var displayedClients: [Client] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return allClients }

        return allClients.filter { client in
            client.name.localizedCaseInsensitiveContains(query)
                || client.contactPerson.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func invoiceCount(for clientID: UUID) -> Int {
        allInvoices.filter { $0.clientID == clientID }.count
    }
    
    private func billedTotal(for clientID: UUID) -> Decimal {
        allInvoices
            .filter { $0.clientID == clientID }
            .reduce(0) { $0 + TotalsCalculator.calculate(for: $1).grandTotal }
    }

    var body: some View {
        List {
            ForEach(displayedClients) { client in
                NavigationLink {
                    ClientDetailView(clientID: client.id)
                } label: {
                    ClientRowView(
                        client: client,
                        invoiceCount: invoiceCount(for: client.id),
                        billedTotal: billedTotal(for: client.id)
                    )
                }
            }
            .onDelete(perform: deleteClients)
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search clients")
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingForm = true
                } label: {
                    Label("New client", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                ClientFormView(draft: Client(name: ""), isNew: true)
            }
        }
        .overlay {
            if displayedClients.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No clients yet")
                        .font(.headline)
                    Text("Tap + to add the first one.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(32)
            }
        }
    }

    // MARK: - Actions

    /// Deleting a client also removes that client's invoices via cascade delete.
    private func deleteClients(at offsets: IndexSet) {
        let clientsToDelete = offsets.map { displayedClients[$0] }
        for client in clientsToDelete {
            // Delete associated invoices first
            let clientInvoices = allInvoices.filter { $0.clientID == client.id }
            for invoice in clientInvoices {
                modelContext.delete(invoice)
            }
            // Then delete the client
            modelContext.delete(client)
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
    .modelContainer(for: [Invoice.self, Client.self, LineItem.self], inMemory: true)
}
