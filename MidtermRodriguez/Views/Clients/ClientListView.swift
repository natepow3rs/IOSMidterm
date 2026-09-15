//
//  ClientListView.swift
//  InvoiceManager
//
//  SCREEN 6: all clients, sorted by name, with search and a button
//  that opens the client form.
//

import SwiftUI

struct ClientListView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var searchText = ""
    @State private var isPresentingForm = false

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
                        billedTotal: store.billedTotal(for: client.id)
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

    /// Deleting a client also removes that client's invoices, which the
    /// controller handles.
    private func deleteClients(at offsets: IndexSet) {
        let ids = offsets.map { displayedClients[$0].id }
        for id in ids {
            store.deleteClient(withID: id)
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
    }
    .environmentObject(InvoiceStore.preview)
}
