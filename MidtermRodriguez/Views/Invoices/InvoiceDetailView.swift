//
//  InvoiceDetailView.swift
//  InvoiceManager
//
//  SCREEN 4: the full invoice. A header shows the amount, how much has
//  been paid, and one button for the obvious next step (send it, or
//  record a payment). Below are the client, dates, line items, totals,
//  payments received and notes, then export and delete.
//
//  The view holds only the invoice's ID and reads the invoice back out
//  of the controller, so edits made elsewhere show up immediately.
//

import SwiftUI

struct InvoiceDetailView: View {

    @EnvironmentObject private var store: InvoiceStore
    @Environment(\.dismiss) private var dismiss

    let invoiceID: Invoice.ID

    @State private var isPresentingEditor = false
    @State private var isConfirmingDelete = false
    @State private var exportedDocument: ExportedDocument?
    @State private var exportErrorMessage: String?
    @State private var paymentDraft: Payment?
    @State private var paymentPendingDeletion: Payment?

    private var invoice: Invoice? {
        store.invoice(withID: invoiceID)
    }

    var body: some View {
        Group {
            if let invoice {
                content(for: invoice)
            } else {
                ContentUnavailableView(
                    "Invoice deleted",
                    systemImage: "doc.text",
                    description: Text("This invoice no longer exists.")
                )
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
        .sheet(item: $paymentDraft) { draft in
            if let invoice {
                NavigationStack {
                    PaymentFormView(
                        draft: draft,
                        invoiceNumber: invoice.number,
                        balanceDue: store.balanceDue(for: invoice)
                    )
                }
            }
        }
        .sheet(item: $exportedDocument) { document in
            NavigationStack {
                InvoicePDFPreviewView(document: document)
            }
        }
        .confirmationDialog(
            "Delete this invoice?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Invoice", role: .destructive, action: deleteInvoice)
        } message: {
            Text("It will be permanently removed from this device.")
        }
        .alert(
            "Couldn't create the PDF",
            isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage ?? "")
        }
        .sensoryFeedback(.success, trigger: invoice?.status)
    }

    // MARK: - Content

    private func content(for invoice: Invoice) -> some View {
        List {
            Section {
                header(for: invoice)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            }

            Section("Billed to") {
                if let client = store.client(withID: invoice.clientID) {
                    NavigationLink {
                        ClientDetailView(clientID: client.id)
                    } label: {
                        HStack(spacing: 12) {
                            ClientAvatarView(client: client, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.name).font(.body.weight(.semibold))
                                if !client.contactPerson.isEmpty {
                                    Text(client.contactPerson)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Text("Client not found").foregroundStyle(.secondary)
                }
            }

            Section("Dates") {
                LabeledContent("Issued", value: invoice.issueDate.shortDateText)
                LabeledContent("Due") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(invoice.dueDate.shortDateText)
                        if invoice.status == .sent {
                            Text(invoice.dueDescription())
                                .font(.caption)
                                .foregroundStyle(invoice.isOverdue() ? Theme.overdue : .secondary)
                        }
                    }
                }
            }

            Section("Line items") {
                ForEach(invoice.lineItems) { item in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.details.isEmpty ? "Untitled item" : item.details)
                            Text("\(item.quantity.formatted()) × \(item.unitPrice.currencyText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(item.amount.currencyText)
                            .monospacedDigit()
                    }
                }
            }

            Section {
                LabeledContent("Subtotal", value: TotalsCalculator.subtotal(of: invoice).currencyText)
                if invoice.vatRate > 0 {
                    LabeledContent(
                        "VAT (\(invoice.vatRate.percentText))",
                        value: TotalsCalculator.vat(of: invoice).currencyText
                    )
                }
                LabeledContent("Total") {
                    Text(TotalsCalculator.total(of: invoice).currencyText)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
                if store.amountPaid(for: invoice) > 0 {
                    LabeledContent("Paid", value: store.amountPaid(for: invoice).currencyText)
                    LabeledContent("Balance due") {
                        Text(store.balanceDue(for: invoice).currencyText)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                    }
                }
            }

            paymentsSection(for: invoice)

            if !invoice.notes.isEmpty {
                Section("Notes") {
                    Text(invoice.notes)
                        .font(.callout)
                }
            }

            Section {
                Button {
                    exportPDF(for: invoice)
                } label: {
                    Label("Export as PDF", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete invoice", systemImage: "trash")
                }
            } footer: {
                Text("Export creates a printable invoice you can share, save to Files, or print.")
            }
        }
    }

    /// Amount, status and the single most useful next action.
    private func header(for invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(store.clientName(for: invoice.clientID))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                StatusBadgeView(invoice: invoice)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(TotalsCalculator.total(of: invoice).currencyText)
                    .font(Theme.heroAmountFont(size: 36))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(invoice.dueDescription())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(invoice.isOverdue() ? Theme.overdue : .secondary)
            }

            if invoice.status == .sent, store.amountPaid(for: invoice) > 0 {
                paymentProgress(for: invoice)
            }

            nextStepButton(for: invoice)
        }
    }

    @ViewBuilder
    private func nextStepButton(for invoice: Invoice) -> some View {
        switch invoice.status {
        case .draft:
            Button {
                store.setStatus(.sent, forInvoiceWithID: invoice.id)
            } label: {
                Label("Mark as sent", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.sent)
            .controlSize(.large)

        case .sent:
            Button {
                paymentDraft = store.makeDraftPayment(for: invoice)
            } label: {
                Label("Record payment", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

        case .paid:
            if store.payments(for: invoice.id).isEmpty {
                Button {
                    store.setStatus(.sent, forInvoiceWithID: invoice.id)
                } label: {
                    Label("Mark as unpaid", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    /// "₱10,000.00 paid of ₱26,208.00" with a bar, for part-paid invoices.
    private func paymentProgress(for invoice: Invoice) -> some View {
        let paid = store.amountPaid(for: invoice)
        let total = TotalsCalculator.total(of: invoice)
        let fraction = total > 0 ? NSDecimalNumber(decimal: paid / total).doubleValue : 0

        return VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: min(fraction, 1))
                .tint(Theme.brand)
            HStack {
                Text("\(paid.currencyText) paid")
                Spacer()
                Text("\(store.balanceDue(for: invoice).currencyText) left")
                    .foregroundStyle(invoice.isOverdue() ? Theme.overdue : Theme.owed)
            }
            .font(.footnote.weight(.medium))
            .monospacedDigit()
        }
    }

    @ViewBuilder
    private func paymentsSection(for invoice: Invoice) -> some View {
        let invoicePayments = store.payments(for: invoice.id)
        if !invoicePayments.isEmpty {
            Section {
                ForEach(invoicePayments) { payment in
                    PaymentRowView(payment: payment)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                paymentPendingDeletion = payment
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("Payments received")
            } footer: {
                Text("Swipe a payment to delete it. A paid invoice goes back to Sent if it's no longer covered.")
            }
            .confirmationDialog(
                "Delete this payment?",
                isPresented: Binding(
                    get: { paymentPendingDeletion != nil },
                    set: { if !$0 { paymentPendingDeletion = nil } }
                ),
                titleVisibility: .visible,
                presenting: paymentPendingDeletion
            ) { payment in
                Button("Delete \(payment.amount.currencyText) Payment", role: .destructive) {
                    store.deletePayment(withID: payment.id)
                }
            }
        }
    }

    // MARK: - Actions

    private func exportPDF(for invoice: Invoice) {
        do {
            exportedDocument = try InvoicePDFExporter.export(invoice, from: store)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func deleteInvoice() {
        store.deleteInvoice(withID: invoiceID)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        InvoiceDetailView(invoiceID: SampleData.invoices[0].id)
    }
    .environmentObject(InvoiceStore.preview)
}
