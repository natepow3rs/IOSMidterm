//
//  SummaryTileView.swift
//  InvoiceManager
//
//  Reusable component: a labelled figure card used on the overview screen.
//

import SwiftUI

struct SummaryTileView: View {

    let title: String
    let value: String
    let symbolName: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HStack {
        SummaryTileView(
            title: "Outstanding",
            value: Decimal(48250).currencyText,
            symbolName: "hourglass",
            tint: .orange
        )
        SummaryTileView(
            title: "Collected",
            value: Decimal(39200).currencyText,
            symbolName: "checkmark.seal",
            tint: .green
        )
    }
    .padding()
}
