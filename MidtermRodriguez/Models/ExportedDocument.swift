//
//  ExportedDocument.swift
//  InvoiceManager
//
//  MODEL: a file the app has generated (for example an invoice PDF)
//  and is about to preview or share.
//

import Foundation

struct ExportedDocument: Identifiable, Hashable {

    let id: UUID
    let fileURL: URL
    let title: String

    init(id: UUID = UUID(), fileURL: URL, title: String) {
        self.id = id
        self.fileURL = fileURL
        self.title = title
    }
}
