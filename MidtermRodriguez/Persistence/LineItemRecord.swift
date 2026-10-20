//
//  LineItemRecord.swift
//  InvoiceManager
//
//  PERSISTENCE: how one invoice line item is stored in the SwiftData
//  database. `position` remembers the order the rows were entered in.
//

import Foundation
import SwiftData

@Model
final class LineItemRecord {

    var uuid: UUID
    var details: String
    var quantity: Decimal
    var unitPrice: Decimal
    var position: Int

    /// The invoice this row belongs to.
    var invoice: InvoiceRecord?

    init(_ item: LineItem, position: Int) {
        self.uuid = item.id
        self.details = item.details
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
        self.position = position
    }

    /// The stored record as the app's model struct.
    var value: LineItem {
        LineItem(
            id: uuid,
            details: details,
            quantity: quantity,
            unitPrice: unitPrice
        )
    }
}
