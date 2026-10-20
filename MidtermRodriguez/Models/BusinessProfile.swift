//
//  BusinessProfile.swift
//  InvoiceManager
//
//  MODEL: the business issuing the invoices. Printed in the header
//  of every exported invoice PDF.
//

import Foundation

struct BusinessProfile: Codable, Hashable {

    var name: String
    var address: String
    var email: String
    var phone: String
    var taxID: String

    init(
        name: String = "",
        address: String = "",
        email: String = "",
        phone: String = "",
        taxID: String = ""
    ) {
        self.name = name
        self.address = address
        self.email = email
        self.phone = phone
        self.taxID = taxID
    }

    /// A profile can only be saved once it has a business name.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Contact lines in the order they are printed, skipping blank fields.
    var contactLines: [String] {
        let taxLine = taxID.isEmpty ? "" : "TIN \(taxID)"
        return [address, email, phone, taxLine].filter { !$0.isEmpty }
    }
}
