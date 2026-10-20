//
//  InvoiceFilter.swift
//  InvoiceManager
//
//  MODEL: the ways the invoice list can be narrowed down. Unlike
//  InvoiceStatus it includes "Overdue", which is worked out from the
//  due date rather than stored.
//

import Foundation

enum InvoiceFilter: String, CaseIterable, Identifiable {

    case all
    case draft
    case sent
    case overdue
    case paid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:     return "All"
        case .draft:   return "Drafts"
        case .sent:    return "Awaiting payment"
        case .overdue: return "Overdue"
        case .paid:    return "Paid"
        }
    }

    func matches(_ invoice: Invoice, asOf date: Date = Date()) -> Bool {
        switch self {
        case .all:     return true
        case .draft:   return invoice.status == .draft
        case .sent:    return invoice.status == .sent && !invoice.isOverdue(asOf: date)
        case .overdue: return invoice.isOverdue(asOf: date)
        case .paid:    return invoice.status == .paid
        }
    }
}
