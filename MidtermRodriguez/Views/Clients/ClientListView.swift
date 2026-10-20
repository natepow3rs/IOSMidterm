//
//  ClientListView.swift
//  InvoiceManager
//
//  SCREEN 6: all clients, sorted by name, showing what each one owes.
//  Search, add, and swipe to delete. Deleting asks first, because it
//  also removes that client's invoices.
//

import SwiftUI

struct ClientListView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var searchText = ""
    @State private var isPresentingForm = false
    @State private var clientPendingDeletion: Client?

    private var displayedClients: [Client] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.sortedClients }

        return store.sortedClients.filter { client in
            client.name.localizedCaseInsensitiveContains(query)
                || client.contactPerson.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            ForEach(displayedClients) { client in
                NavigationLink {
                    ClientDetailView(clientID: client.id)
                } label: {
                    ClientRowView(
                        client: client,
                        invoiceCount: store.invoices(for: client.id).count,
                        amountOwed: store.receivableTotal(for: client.id),
                        hasOverdue: store.hasOverdueInvoices(for: client.id)
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        clientPendingDeletion = client
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
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
                emptyState
            }
        }
        .confirmationDialog(
            "Delete this client?",
            isPresented: Binding(
                get: { clientPendingDeletion != nil },
                set: { if !$0 { clientPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: clientPendingDeletion
        ) { client in
            Button("Delete \(client.name)", role: .destructive) {
                store.deleteClient(withID: client.id)
            }
        } message: { client in
            Text(deletionMessage(for: client))
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var emptyState: some View {
        if searchText.isEmpty {
            ContentUnavailableView {
                Label("No clients yet", systemImage: "person.2")
            } description: {
                Text("Add the businesses you bill so you can start invoicing them.")
            } actions: {
                Button("Add a client") { isPresentingForm = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView.search(text: searchText)
        }
    }

    private func deletionMessage(for client: Client) -> String {
        let count = store.invoices(for: client.id).count
        guard count > 0 else { return "\(client.name) will be permanently removed." }
        return "\(client.name) and their \(count) invoice\(count == 1 ? "" : "s") will be permanently removed."
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
    .environmentObject(InvoiceStore.preview)
}
