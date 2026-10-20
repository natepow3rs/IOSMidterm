//
//  Invoice+Display.swift
//  InvoiceManager
//
//  Short human-readable text about an invoice's due date. Kept out of
//  the views so every screen describes due dates the same way.
//

import Foundation

extension Invoice {

    /// For example "Due in 5 days", "Due today", "3 days overdue" or "Paid".
    func dueDescription(asOf date: Date = Date()) -> String {
        switch status {
        case .paid:
            return "Paid"
        case .draft:
            return "Draft, due \(dueDate.shortDateText)"
        case .sent:
            let days = daysUntilDue(asOf: date)
            if days < -1 { return "\(-days) days overdue" }
            if days == -1 { return "1 day overdue" }
            if days == 0 { return "Due today" }
            if days == 1 { return "Due tomorrow" }
            return "Due in \(days) days"
        }
    }
}
