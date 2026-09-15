//
//  InvoiceRowView.swift
//  InvoiceManager
//
//  Reusable component: one invoice summarised as a list row.
//  Used by the invoice list, the client detail screen and the overview.
//

import SwiftUI

struct InvoiceRowView: View {

    let invoice: Invoice
    let clientName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number)
                    .font(.subheadline.weight(.semibold))

                Text(clientName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StatusBadgeView(status: invoice.status)

                    if invoice.isOverdue() {
                        Text("Overdue")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(TotalsCalculator.total(of: invoice).currencyText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text("Due \(invoice.dueDate.shortDateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        InvoiceRowView(
            invoice: SampleData.invoices[0],
            clientName: SampleData.clients[0].name
        )
    }
}
