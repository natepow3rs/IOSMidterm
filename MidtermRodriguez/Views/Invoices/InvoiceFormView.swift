//
//  InvoiceFormView.swift
//  InvoiceManager
//
//  SCREEN 5: create or edit an invoice. Payment terms are one tap
//  (Net 7/15/30), VAT is a simple on/off switch, and the form says
//  what's missing whenever Save is unavailable.
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

    /// The invoice as it was when the form opened, to detect edits.
    private let original: Invoice

    init(draft: Invoice, isNew: Bool) {
        _draft = State(initialValue: draft)
        self.isNew = isNew
        self.original = draft
    }

    /// Prevents swiping the sheet away and losing edits by accident.
    /// Cancel still discards them on purpose.
    private var hasUnsavedChanges: Bool {
        draft != original
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
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isNew ? "New Invoice" : "Edit Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(hasUnsavedChanges)
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
        Section {
            DatePicker("Issue date", selection: $draft.issueDate, displayedComponents: .date)
            DatePicker("Due date", selection: $draft.dueDate, in: draft.issueDate..., displayedComponents: .date)

            HStack(spacing: 8) {
                Text("Terms")
                    .foregroundStyle(.secondary)
                Spacer()
                ForEach(paymentTermOptions, id: \.self) { days in
                    termButton(days: days)
                }
            }
            .font(.subheadline)
        } header: {
            Text("Dates")
        } footer: {
            Text("Net 15 means payment is due 15 days after the issue date.")
        }
    }

    private let paymentTermOptions = [7, 15, 30]

    private func termButton(days: Int) -> some View {
        let isSelected = currentTermInDays == days
        return Button("Net \(days)") {
            draft.dueDate = Calendar.current.date(byAdding: .day, value: days, to: draft.issueDate)
                ?? draft.dueDate
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? Theme.brand : .secondary)
        .controlSize(.small)
    }

    /// Days between issue and due date, used to highlight the matching term.
    private var currentTermInDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: draft.issueDate),
            to: calendar.startOfDay(for: draft.dueDate)
        ).day ?? 0
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
        Section {
            LabeledContent("Subtotal", value: TotalsCalculator.subtotal(of: draft).currencyText)

            Toggle("Add VAT (\(AppConfiguration.defaultVATRate.percentText))", isOn: chargesVATBinding)

            if draft.vatRate > 0 {
                LabeledContent("VAT", value: TotalsCalculator.vat(of: draft).currencyText)
            }

            LabeledContent("Total") {
                Text(TotalsCalculator.total(of: draft).currencyText)
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        } header: {
            Text("Totals")
        } footer: {
            if let problem = validationMessage {
                Text(problem)
                    .foregroundStyle(Theme.overdue)
            }
        }
    }

    /// Turns VAT on (at the standard rate) or off.
    private var chargesVATBinding: Binding<Bool> {
        Binding(
            get: { draft.vatRate > 0 },
            set: { draft.vatRate = $0 ? AppConfiguration.defaultVATRate : 0 }
        )
    }

    /// Explains why Save is disabled, so the user knows what to fix.
    private var validationMessage: String? {
        if draft.number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add an invoice number to save."
        }
        if !draft.lineItems.contains(where: { $0.isValid }) {
            return "Describe at least one line item to save."
        }
        return nil
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
