//
//  CollectionBarView.swift
//  InvoiceManager
//
//  Reusable component: one horizontal bar split into what has been
//  collected, what is owed but not yet due, and what is overdue.
//  Shows at a glance how healthy collections are.
//

import SwiftUI

struct CollectionBarView: View {

    let collected: Decimal
    let owed: Decimal
    let overdue: Decimal

    private var total: Decimal { collected + owed + overdue }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                segment(collected, color: Theme.brand, width: proxy.size.width)
                segment(owed, color: Theme.owed, width: proxy.size.width)
                segment(overdue, color: Theme.overdue, width: proxy.size.width)
            }
        }
        .frame(height: 10)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .clipShape(Capsule())
        .accessibilityElement()
        .accessibilityLabel(
            "Collected \(collected.currencyText), owed \(owed.currencyText), overdue \(overdue.currencyText)"
        )
    }

    @ViewBuilder
    private func segment(_ value: Decimal, color: Color, width: CGFloat) -> some View {
        if value > 0, total > 0 {
            let share = NSDecimalNumber(decimal: value / total).doubleValue
            color.frame(width: max(4, width * share))
        }
    }
}

#Preview {
    CollectionBarView(collected: 39500, owed: 26880, overdue: 30120)
        .padding()
}
