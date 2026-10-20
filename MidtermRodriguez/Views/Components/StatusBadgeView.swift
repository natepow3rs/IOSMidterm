//
//  StatusBadgeView.swift
//  InvoiceManager
//
//  Reusable component: a small coloured pill showing where an invoice
//  stands. An overdue invoice shows "Overdue" in red instead of "Sent",
//  so the most urgent state is never hidden. Each state also has its own
//  icon, so colour is never the only signal.
//

import SwiftUI

struct StatusBadgeView: View {

    let status: InvoiceStatus
    var isOverdue: Bool = false

    private var title: String {
        isOverdue ? "Overdue" : status.displayName
    }

    private var symbolName: String {
        isOverdue ? "exclamationmark.circle.fill" : status.symbolName
    }

    private var tint: Color {
        if isOverdue { return Theme.overdue }
        switch status {
        case .draft: return Theme.draft
        case .sent:  return Theme.sent
        case .paid:  return Theme.brand
        }
    }

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.caption2.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(tint)
            .background(tint.opacity(0.14), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Status: \(title)")
    }
}

extension StatusBadgeView {

    /// Badge for a specific invoice, taking its due date into account.
    init(invoice: Invoice) {
        self.init(status: invoice.status, isOverdue: invoice.isOverdue())
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(InvoiceStatus.allCases) { status in
            StatusBadgeView(status: status)
        }
        StatusBadgeView(status: .sent, isOverdue: true)
    }
    .padding()
}
