//
//  StatusBadgeView.swift
//  InvoiceManager
//
//  Reusable component: a small coloured pill showing an invoice status.
//  The status-to-colour mapping lives here because colour is a
//  presentation concern, not a model concern.
//

import SwiftUI

struct StatusBadgeView: View {

    let status: InvoiceStatus

    private var tint: Color {
        switch status {
        case .draft: return .gray
        case .sent:  return .orange
        case .paid:  return .green
        }
    }

    var body: some View {
        Label(status.displayName, systemImage: status.symbolName)
            .font(.caption.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(InvoiceStatus.allCases) { status in
            StatusBadgeView(status: status)
        }
    }
    .padding()
}
