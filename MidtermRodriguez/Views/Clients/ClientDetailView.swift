//
//  ClientDetailView.swift
//  InvoiceManager
//
//  SCREEN 7: one client. A header with what they owe and quick actions
//  (new invoice, call, email), then contact details, billing totals and every
//  invoice issued to them.
//

import SwiftUI

struct ClientDetailView: View {

    @EnvironmentObject private var store: InvoiceStore
    @Environment(\.dismiss) private var dismiss

    let clientID: Client.ID

    @State private var isPresentingEditor = false
    @State private var invoiceDraft: Invoice?
    @State private var isConfirmingDelete = false

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
                ContentUnavailableView(
                    "Client deleted",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("This client no longer exists.")
                )
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
        .sheet(item: $invoiceDraft) { draft in
            NavigationStack {
                InvoiceFormView(draft: draft, isNew: true)
            }
        }
        .confirmationDialog(
            "Delete this client?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Client", role: .destructive, action: deleteClient)
        } message: {
            Text(deletionMessage)
        }
    }

    // MARK: - Content

    private func content(for client: Client) -> some View {
        List {
            Section {
                header(for: client)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            }

            if hasContactDetails(client) {
                Section("Contact") {
                    if !client.contactPerson.isEmpty {
                        LabeledContent("Contact person", value: client.contactPerson)
                    }
                    if !client.email.isEmpty {
                        LabeledContent("Email", value: client.email)
                    }
                    if !client.phone.isEmpty {
                        LabeledContent("Phone", value: client.phone)
                    }
                    if !client.address.isEmpty {
                        LabeledContent("Address", value: client.address)
                    }
                }
            }

            Section("Billing") {
                LabeledContent("Total billed", value: store.billedTotal(for: clientID).currencyText)
                LabeledContent("Unpaid invoices", value: "\(store.unpaidInvoiceCount(for: clientID))")
            }

            Section("Invoices") {
                if clientInvoices.isEmpty {
                    Text("No invoices for this client yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(clientInvoices) { invoice in
                        NavigationLink {
                            InvoiceDetailView(invoiceID: invoice.id)
                        } label: {
                            InvoiceRowView(
                                invoice: invoice,
                                clientName: client.name,
                                showsClientName: false
                            )
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete client", systemImage: "trash")
                }
            }
        }
    }

    private func header(for client: Client) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ClientAvatarView(client: client, size: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    owedSummary
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    invoiceDraft = store.makeDraftInvoice(for: client.id)
                } label: {
                    Label("New invoice", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let phoneURL = phoneURL(for: client) {
                    Link(destination: phoneURL) {
                        Label("Call", systemImage: "phone.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Call \(client.name)")
                }

                if let emailURL = emailURL(for: client) {
                    Link(destination: emailURL) {
                        Label("Email", systemImage: "envelope.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Email \(client.name)")
                }
            }
            .controlSize(.large)
            .labelStyle(.titleAndIcon)
        }
    }

    @ViewBuilder
    private var owedSummary: some View {
        let owed = store.receivableTotal(for: clientID)
        if owed > 0 {
            Text("Owes \(owed.currencyText)")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(store.hasOverdueInvoices(for: clientID) ? Theme.overdue : Theme.owed)
        } else {
            Text("Nothing owed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func hasContactDetails(_ client: Client) -> Bool {
        !client.contactPerson.isEmpty || !client.email.isEmpty
            || !client.phone.isEmpty || !client.address.isEmpty
    }

    /// A tel: link using only the digits and a leading +, e.g. "+639171234567".
    private func phoneURL(for client: Client) -> URL? {
        let digits = client.phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    private func emailURL(for client: Client) -> URL? {
        let address = client.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return nil }
        return URL(string: "mailto:\(address)")
    }

    private var deletionMessage: String {
        let count = clientInvoices.count
        guard count > 0 else { return "This client will be permanently removed." }
        return "This client and their \(count) invoice\(count == 1 ? "" : "s") will be permanently removed."
    }

    // MARK: - Actions

    private func deleteClient() {
        store.deleteClient(withID: clientID)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ClientDetailView(clientID: SampleData.clients[0].id)
    }
    .environmentObject(InvoiceStore.preview)
}
