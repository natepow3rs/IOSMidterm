//
//  InvoiceRowView.swift
//  InvoiceManager
//
//  Reusable component: one invoice summarised as a list row.
//  Leads with the client (how people think about who owes them),
//  then the invoice number and when it's due.
//  Used by the invoice list, the client detail screen and the overview.
//

import SwiftUI

struct InvoiceRowView: View {

    let invoice: Invoice
    let clientName: String

    /// Hide the client name when the row is already on that client's screen.
    var showsClientName: Bool = true

    private var isOverdue: Bool { invoice.isOverdue() }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(showsClientName ? clientName : invoice.number)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(isOverdue ? Theme.overdue : .secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                Text(TotalsCalculator.total(of: invoice).currencyText)
                    .font(Theme.rowAmountFont)
                    .monospacedDigit()

                StatusBadgeView(invoice: invoice)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        showsClientName
            ? "\(invoice.number), \(invoice.dueDescription().lowercasedFirstLetter)"
            : invoice.dueDescription()
    }
}

private extension String {

    /// "Due in 5 days" becomes "due in 5 days" so it reads well mid-sentence.
    var lowercasedFirstLetter: String {
        prefix(1).lowercased() + dropFirst()
    }
}

#Preview {
    List {
        ForEach(SampleData.invoices) { invoice in
            InvoiceRowView(invoice: invoice, clientName: "Santex Building Company")
        }
    }
}
