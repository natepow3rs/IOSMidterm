//
//  InvoiceDatabase.swift
//  InvoiceManager
//
//  PERSISTENCE: creates the SwiftData ModelContainer — the on-device
//  database file that keeps clients, invoices and settings between launches.
//

import Foundation
import SwiftData

enum InvoiceDatabase {

    /// Every table (entity) stored in the database.
    static let schema = Schema([
        ClientRecord.self,
        InvoiceRecord.self,
        LineItemRecord.self,
        PaymentRecord.self,
        BusinessProfileRecord.self
    ])

    /// The database saved on the device. Falls back to a temporary in-memory
    /// database (and logs the error) if the file cannot be opened, so the
    /// app still launches.
    static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema)
            )
        } catch {
            print("Could not open the database, using memory only: \(error)")
            return makeInMemoryContainer()
        }
    }

    /// A throw-away database used by Xcode previews.
    static func makeInMemoryContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Could not create an in-memory database: \(error)")
        }
    }
}
