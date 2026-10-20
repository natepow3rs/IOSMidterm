//
//  PaymentRowView.swift
//  InvoiceManager
//
//  Reusable component: one payment as a list row — how it was paid,
//  when, its reference number, and the amount.
//

import SwiftUI

struct PaymentRowView: View {

    let payment: Payment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: payment.method.symbolName)
                .font(.body)
                .foregroundStyle(Theme.brand)
                .frame(width: 36, height: 36)
                .background(Theme.brand.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(payment.method.displayName)
                    .font(.body.weight(.medium))

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(payment.amount.currencyText)
                .font(Theme.rowAmountFont)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        payment.reference.isEmpty
            ? payment.date.shortDateText
            : "\(payment.date.shortDateText), ref. \(payment.reference)"
    }
}

#Preview {
    List {
        ForEach(SampleData.payments) { payment in
            PaymentRowView(payment: payment)
        }
    }
}
