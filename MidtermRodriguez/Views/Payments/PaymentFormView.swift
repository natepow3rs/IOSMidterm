//
//  PaymentFormView.swift
//  InvoiceManager
//
//  SCREEN 12: record money received against an invoice. The amount
//  starts at the remaining balance, so a full payment is one tap on Save;
//  change it for a partial payment.
//
//  Same draft-then-save pattern as the other forms.
//

import SwiftUI

struct PaymentFormView: View {

    @EnvironmentObject private var store: InvoiceStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Payment

    let invoiceNumber: String
    let balanceDue: Decimal

    init(draft: Payment, invoiceNumber: String, balanceDue: Decimal) {
        _draft = State(initialValue: draft)
        self.invoiceNumber = invoiceNumber
        self.balanceDue = balanceDue
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Balance due") {
                    Text(balanceDue.currencyText)
                        .monospacedDigit()
                }

                HStack {
                    Text("Amount received")
                    Spacer()
                    TextField("0.00", value: $draft.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.body.weight(.semibold))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                }

                if draft.amount != balanceDue {
                    Button("Use full balance") {
                        draft.amount = balanceDue
                    }
                }
            } header: {
                Text("Amount")
            } footer: {
                Text(amountFooter)
                    .foregroundStyle(validationMessage == nil ? Color.secondary : Theme.overdue)
            }

            Section("Details") {
                DatePicker("Date received", selection: $draft.date, in: ...Date(), displayedComponents: .date)

                Picker("Method", selection: $draft.method) {
                    ForEach(PaymentMethod.allCases) { method in
                        Label(method.displayName, systemImage: method.symbolName)
                            .tag(method)
                    }
                }

                if draft.method.usesReference {
                    TextField("Reference number (optional)", text: $draft.reference)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Record Payment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(validationMessage != nil)
            }
        }
    }

    // MARK: - Validation

    private var validationMessage: String? {
        if draft.amount <= 0 {
            return "Enter the amount you received."
        }
        if draft.amount > balanceDue {
            return "That's more than the \(balanceDue.currencyText) still owed on \(invoiceNumber)."
        }
        return nil
    }

    private var amountFooter: String {
        if let validationMessage { return validationMessage }
        let remaining = balanceDue - draft.amount
        return remaining > 0
            ? "\(remaining.currencyText) will still be owed after this payment."
            : "This settles \(invoiceNumber) in full."
    }

    // MARK: - Actions

    private func save() {
        draft.reference = draft.method.usesReference
            ? draft.reference.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        store.recordPayment(draft)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PaymentFormView(
            draft: Payment(invoiceID: SampleData.invoices[0].id, amount: 16208),
            invoiceNumber: SampleData.invoices[0].number,
            balanceDue: 16208
        )
    }
    .environmentObject(InvoiceStore.preview)
}
