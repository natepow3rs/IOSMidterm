//
//  LineItemEditorRow.swift
//  InvoiceManager
//
//  Reusable component: the editable row used inside the invoice form.
//  It writes straight back into the draft through a Binding.
//

import SwiftUI

struct LineItemEditorRow: View {

    @Binding var item: LineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Description of work", text: $item.details)
                .font(.subheadline)

            HStack(spacing: 10) {
                LabeledField(label: "Qty") {
                    TextField("1", value: $item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                }
                .frame(width: 70)

                LabeledField(label: "Unit price") {
                    TextField("0", value: $item.unitPrice, format: .number)
                        .keyboardType(.decimalPad)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Amount")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(item.amount.currencyText)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Small private helper so the two numeric fields stay visually consistent.
private struct LabeledField<Content: View>: View {

    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            content
                .textFieldStyle(.roundedBorder)
                .font(.caption)
        }
    }
}

#Preview {
    Form {
        LineItemEditorRow(
            item: .constant(LineItem(details: "Bookkeeping", quantity: 2, unitPrice: 1500))
        )
    }
}
