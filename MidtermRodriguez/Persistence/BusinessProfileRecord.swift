//
//  BusinessProfileRecord.swift
//  InvoiceManager
//
//  PERSISTENCE: the business profile stored in the SwiftData database.
//  The app only ever keeps one of these rows.
//

import Foundation
import SwiftData

@Model
final class BusinessProfileRecord {

    var name: String
    var address: String
    var email: String
    var phone: String
    var taxID: String

    init(_ profile: BusinessProfile) {
        self.name = profile.name
        self.address = profile.address
        self.email = profile.email
        self.phone = profile.phone
        self.taxID = profile.taxID
    }

    /// Copies edited values from the struct into the stored record.
    func apply(_ profile: BusinessProfile) {
        name = profile.name
        address = profile.address
        email = profile.email
        phone = profile.phone
        taxID = profile.taxID
    }

    /// The stored record as the app's model struct.
    var value: BusinessProfile {
        BusinessProfile(
            name: name,
            address: address,
            email: email,
            phone: phone,
            taxID: taxID
        )
    }
}
