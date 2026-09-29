//
//  Client.swift
//  InvoiceManager
//
//  MODEL: a customer that invoices are issued to.
//  Now a SwiftData model for persistent storage.
//

import Foundation
import SwiftData

@Model
final class Client {

    var id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var address: String
    
    // Relationship to invoices (optional, for bidirectional relationship)
    @Relationship(deleteRule: .cascade, inverse: \Invoice.client)
    var invoices: [Invoice]?

    init(
        id: UUID = UUID(),
        name: String,
        contactPerson: String = "",
        email: String = "",
        address: String = ""
    ) {
        self.id = id
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.address = address
    }

    /// A client can only be saved once it has a name.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Initials used by the avatar circle in the client list.
    var initials: String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}
