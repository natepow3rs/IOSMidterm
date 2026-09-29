//
//  ClientDetailView.swift
//  InvoiceManager
//
//  SCREEN 7: one client's contact details, their billing summary,
//  and every invoice issued to them.
//

import SwiftUI
import SwiftData

struct ClientDetailView: View {

    @Query private var allClients: [Client]
    @Query private var allInvoices: [Invoice]

    let clientID: Client.ID

    @State private var isPresentingEditor = false

    private var client: Client? {
        allClients.first { $0.id == clientID }
    }

    private var clientInvoices: [Invoice] {
        allInvoices.filter { $0.clientID == clientID }
            .sorted { $0.issueDate > $1.issueDate }
    }
    
    private var billedTotal: Decimal {
        clientInvoices.reduce(0) { $0 + TotalsCalculator.calculate(for: $1).grandTotal }
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
                LabeledContent("Total billed", value: billedTotal.currencyText)
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
    .modelContainer(for: [Invoice.self, Client.self, LineItem.self], inMemory: true)
}
