//
//  InvoiceFormView.swift
//  InvoiceManager
//
//  SCREEN 5: create or edit an invoice.
//
//  The form edits a local copy (`draft`) and only hands it to the
//  controller when Save is tapped, so cancelling changes nothing.
//

import SwiftUI

struct InvoiceFormView: View {

    @EnvironmentObject private var store: InvoiceStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Invoice

    /// True when creating, false when editing an existing invoice.
    private let isNew: Bool

    init(draft: Invoice, isNew: Bool) {
        _draft = State(initialValue: draft)
        self.isNew = isNew
    }

    var body: some View {
        Form {
            detailsSection
            datesSection
            lineItemsSection
            totalsSection

            Section("Notes") {
                TextField("Payment instructions, terms, reminders…",
                          text: $draft.notes,
                          axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .navigationTitle(isNew ? "New Invoice" : "Edit Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!draft.isValid)
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Invoice number", text: $draft.number)

            Picker("Client", selection: $draft.clientID) {
                ForEach(store.sortedClients) { client in
                    Text(client.name).tag(client.id)
                }
            }

            Picker("Status", selection: $draft.status) {
                ForEach(InvoiceStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
        }
    }

    private var datesSection: some View {
        Section("Dates") {
            DatePicker("Issue date", selection: $draft.issueDate, displayedComponents: .date)
            DatePicker("Due date", selection: $draft.dueDate, in: draft.issueDate..., displayedComponents: .date)
        }
    }

    private var lineItemsSection: some View {
        Section {
            ForEach($draft.lineItems) { $item in
                LineItemEditorRow(item: $item)
            }
            .onDelete(perform: deleteLineItems)

            Button {
                draft.lineItems.append(LineItem())
            } label: {
                Label("Add line item", systemImage: "plus.circle.fill")
                    .font(.subheadline)
            }
        } header: {
            Text("Line items")
        } footer: {
            Text("Swipe a row to remove it. At least one described item is required.")
        }
    }

    private var totalsSection: some View {
        Section("Totals") {
            LabeledContent("Subtotal", value: TotalsCalculator.subtotal(of: draft).currencyText)

            HStack {
                Text("VAT rate")
                Spacer()
                TextField("0.12", value: $draft.vatRate, format: .percent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
            }

            LabeledContent("VAT", value: TotalsCalculator.vat(of: draft).currencyText)

            LabeledContent("Total") {
                Text(TotalsCalculator.total(of: draft).currencyText)
                    .font(.headline)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Actions

    private func deleteLineItems(at offsets: IndexSet) {
        draft.lineItems.remove(atOffsets: offsets)
    }

    private func save() {
        // Blank rows are dropped so they never reach the controller.
        draft.lineItems.removeAll { !$0.isValid }

        if isNew {
            store.addInvoice(draft)
        } else {
            store.update(draft)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        InvoiceFormView(draft: SampleData.invoices[0], isNew: false)
    }
    .environmentObject(InvoiceStore.preview)
}
