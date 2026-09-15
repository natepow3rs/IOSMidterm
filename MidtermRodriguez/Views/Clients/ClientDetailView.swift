//
//  ClientDetailView.swift
//  InvoiceManager
//
//  SCREEN 7: one client's contact details, their billing summary,
//  and every invoice issued to them.
//

import SwiftUI

struct ClientDetailView: View {

    @EnvironmentObject private var store: InvoiceStore

    let clientID: Client.ID

    @State private var isPresentingEditor = false

    private var client: Client? {
        store.client(withID: clientID)
    }

    private var clientInvoices: [Invoice] {
        store.invoices(for: clientID)
    }

    var body: some View {
        Group {
            if let client {
                content(for: client)
            } else {
                Text("This client has been deleted.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(client?.name ?? "Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isPresentingEditor = true }
                    .disabled(client == nil)
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            if let client {
                NavigationStack {
                    ClientFormView(draft: client, isNew: false)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(for client: Client) -> some View {
        List {
            Section("Contact") {
                if !client.contactPerson.isEmpty {
                    LabeledContent("Contact", value: client.contactPerson)
                }
                if !client.email.isEmpty {
                    LabeledContent("Email", value: client.email)
                }
                if !client.address.isEmpty {
                    LabeledContent("Address", value: client.address)
                }
            }

            Section("Billing summary") {
                LabeledContent("Total billed", value: store.billedTotal(for: clientID).currencyText)
                LabeledContent("Invoices", value: "\(clientInvoices.count)")
                LabeledContent(
                    "Unpaid",
                    value: "\(clientInvoices.filter { $0.status.isOutstanding }.count)"
                )
            }

            Section("Invoices") {
                if clientInvoices.isEmpty {
                    Text("No invoices issued to this client yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(clientInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoiceID: invoice.id)
                        } label: {
                            InvoiceRowView(invoice: invoice, clientName: client.name)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(clientID: SampleData.clients[0].id)
    }
    .environmentObject(InvoiceStore.preview)
}
