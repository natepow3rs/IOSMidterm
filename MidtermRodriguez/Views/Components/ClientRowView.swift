//
//  ClientRowView.swift
//  InvoiceManager
//
//  Reusable component: one client summarised as a list row. The figure
//  on the right is what the client owes now, which is the number people
//  usually come to the client list for.
//

import SwiftUI

struct ClientRowView: View {

    let client: Client
    let invoiceCount: Int
    let amountOwed: Decimal
    var hasOverdue: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ClientAvatarView(client: client)

            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if amountOwed > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(amountOwed.currencyText)
                        .font(Theme.rowAmountFont)
                        .monospacedDigit()
                        .foregroundStyle(hasOverdue ? Theme.overdue : Theme.owed)
                    Text(hasOverdue ? "Overdue" : "Owed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Settled")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let invoices = "\(invoiceCount) invoice\(invoiceCount == 1 ? "" : "s")"
        return client.contactPerson.isEmpty ? invoices : "\(client.contactPerson), \(invoices)"
    }
}

#Preview {
    List {
        ClientRowView(client: SampleData.clients[0], invoiceCount: 2, amountOwed: 25000, hasOverdue: true)
        ClientRowView(client: SampleData.clients[1], invoiceCount: 1, amountOwed: 12000)
        ClientRowView(client: SampleData.clients[2], invoiceCount: 1, amountOwed: 0)
    }
}
