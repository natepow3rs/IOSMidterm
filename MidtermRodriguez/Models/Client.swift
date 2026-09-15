//
//  Client.swift
//  InvoiceManager
//
//  MODEL: a customer that invoices are issued to.
//  Pure data + validation only. No SwiftUI imports here.
//

import Foundation

struct Client: Identifiable, Codable, Hashable {

    let id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var address: String

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
