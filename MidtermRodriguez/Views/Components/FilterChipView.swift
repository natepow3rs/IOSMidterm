//
//  FilterChipView.swift
//  InvoiceManager
//
//  Reusable component: a selectable chip with a title and a count,
//  used for the invoice list filters.
//

import SwiftUI

struct FilterChipView: View {

    let title: String
    let count: Int
    let isSelected: Bool
    var tint: Color = Theme.brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                isSelected ? tint : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        FilterChipView(title: "All", count: 4, isSelected: true) { }
        FilterChipView(title: "Overdue", count: 1, isSelected: false, tint: Theme.overdue) { }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
