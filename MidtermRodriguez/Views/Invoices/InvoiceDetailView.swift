//
//  InvoiceDetailView.swift
//  InvoiceManager
//
//  SCREEN 4: the full invoice — client, dates, line items, computed
//  totals, and the controls that change its status.
//
//  The view holds only the invoice's ID and reads the invoice back from
//  SwiftData, so edits made elsewhere show up immediately.
//

import SwiftUI
import SwiftData

struct InvoiceDetailView: View {

    @Query private var allInvoices: [Invoice]
    @Query private var allClients: [Client]
    @Environment(\.modelContext) private var modelContext

    let invoiceID: Invoice.ID

    @State private var isPresentingEditor = false

    private var invoice: Invoice? {
        allInvoices.first { $0.id == invoiceID }
    }
    
    private func client(withID id: UUID) -> Client? {
        allClients.first { $0.id == id }
    }

    var body: some View {
        Group {
            if let invoice {
                content(for: invoice)
            } else {
                Text("This invoice has been deleted.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(invoice?.number ?? "Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isPresentingEditor = true }
                    .disabled(invoice == nil)
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            if let invoice {
                NavigationStack {
                    InvoiceFormView(draft: invoice, isNew: false)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(for invoice: Invoice) -> some View {
        List {
            Section("Status") {
                Picker("Status", selection: statusBinding(for: invoice)) {
                    ForEach(InvoiceStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.segmented)

                if invoice.isOverdue() {
                    Label(
                        "Overdue by \(abs(invoice.daysUntilDue())) day\(abs(invoice.daysUntilDue()) == 1 ? "" : "s")",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.red)
                }
            }

            Section("Billed to") {
                if let client = client(withID: invoice.clientID) {
                    NavigationLink {
                        ClientDetailView(clientID: client.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.name).font(.subheadline.weight(.semibold))
                            if !client.contactPerson.isEmpty {
                                Text(client.contactPerson)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Client not found").foregroundStyle(.secondary)
                }
            }

            Section("Dates") {
                LabeledContent("Issued", value: invoice.issueDate.shortDateText)
                LabeledContent("Due", value: invoice.dueDate.shortDateText)
            }

            Section("Line items") {
                ForEach(invoice.lineItems) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.details.isEmpty ? "Untitled item" : item.details)
                                .font(.subheadline)
                            Text("\(item.quantity.formatted()) × \(item.unitPrice.currencyText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(item.amount.currencyText)
                            .font(.subheadline)
                            .monospacedDigit()
                    }
                }
            }

            Section("Totals") {
                LabeledContent("Subtotal", value: TotalsCalculator.subtotal(of: invoice).currencyText)
                LabeledContent("VAT (\(invoice.vatRate.percentText))", value: TotalsCalculator.vat(of: invoice).currencyText)
                LabeledContent("Total") {
                    Text(TotalsCalculator.total(of: invoice).currencyText)
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            if !invoice.notes.isEmpty {
                Section("Notes") {
                    Text(invoice.notes).font(.footnote)
                }
            }
        }
    }

    // MARK: - Bindings

    /// Writes status changes directly to the SwiftData model.
    private func statusBinding(for invoice: Invoice) -> Binding<InvoiceStatus> {
        Binding(
            get: { invoice.status },
            set: { newStatus in
                invoice.status = newStatus
                try? modelContext.save()
            }
        )
    }
}

#Preview {
    NavigationStack {
        InvoiceDetailView(invoiceID: SampleData.invoices[0].id)
    }
    .modelContainer(for: [Invoice.self, Client.self, LineItem.self], inMemory: true)
}
