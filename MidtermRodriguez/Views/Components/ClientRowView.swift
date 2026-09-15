//
//  ClientRowView.swift
//  InvoiceManager
//
//  Reusable component: one client summarised as a list row.
//

import SwiftUI

struct ClientRowView: View {

    let client: Client
    let invoiceCount: Int
    let billedTotal: Decimal

    var body: some View {
        HStack(spacing: 12) {
            Text(client.initials)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text("\(invoiceCount) invoice\(invoiceCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(billedTotal.currencyText)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ClientRowView(
            client: SampleData.clients[0],
            invoiceCount: 2,
            billedTotal: 25000
        )
    }
}
