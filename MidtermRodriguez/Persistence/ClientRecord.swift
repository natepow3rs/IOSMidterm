//
//  ClientRecord.swift
//  InvoiceManager
//
//  PERSISTENCE: how a Client is stored in the SwiftData database.
//  The rest of the app works with the plain `Client` struct; only
//  InvoiceStore converts between the two.
//

import Foundation
import SwiftData

@Model
final class ClientRecord {

    @Attribute(.unique) var uuid: UUID
    var name: String
    var contactPerson: String
    var email: String
    var address: String

    init(_ client: Client) {
        self.uuid = client.id
        self.name = client.name
        self.contactPerson = client.contactPerson
        self.email = client.email
        self.address = client.address
    }

    /// Copies edited values from the struct into the stored record.
    func apply(_ client: Client) {
        name = client.name
        contactPerson = client.contactPerson
        email = client.email
        address = client.address
    }

    /// The stored record as the app's model struct.
    var value: Client {
        Client(
            id: uuid,
            name: name,
            contactPerson: contactPerson,
            email: email,
            address: address
        )
    }
}
