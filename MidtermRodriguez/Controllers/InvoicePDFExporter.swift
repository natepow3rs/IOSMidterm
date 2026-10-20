//
//  InvoicePDFExporter.swift
//  InvoiceManager
//
//  CONTROLLER: turns an invoice into a PDF file. It gathers the data
//  from InvoiceStore, splits the line items into pages, renders each
//  page with InvoicePDFPageView, and writes the result to a temporary file.
//

import SwiftUI
import CoreGraphics

enum InvoicePDFExporter {

    /// `nonisolated` because errors must be usable from any thread.
    nonisolated enum ExportError: LocalizedError {
        case clientNotFound
        case renderingFailed

        var errorDescription: String? {
            switch self {
            case .clientNotFound:  return "The client for this invoice could not be found."
            case .renderingFailed: return "The PDF file could not be created."
            }
        }
    }

    /// US Letter, in points.
    static let pageSize = CGSize(width: 612, height: 792)

    /// The first page also carries the "Bill to" block, so it holds fewer rows.
    static let firstPageCapacity = 8
    static let continuationPageCapacity = 14

    // MARK: - Export

    /// Renders the invoice and returns the generated document, ready to preview or share.
    static func export(_ invoice: Invoice, from store: InvoiceStore) throws -> ExportedDocument {
        guard let client = store.client(withID: invoice.clientID) else {
            throw ExportError.clientNotFound
        }

        let fileURL = URL.temporaryDirectory.appending(path: "\(fileName(for: invoice)).pdf")
        let pages = paginate(invoice.lineItems)

        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(fileURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw ExportError.renderingFailed
        }

        for (index, items) in pages.enumerated() {
            let page = InvoicePDFPageView(
                invoice: invoice,
                client: client,
                business: store.businessProfile,
                lineItems: items,
                amountPaid: store.amountPaid(for: invoice),
                pageNumber: index + 1,
                pageCount: pages.count
            )

            let renderer = ImageRenderer(content: page)
            renderer.proposedSize = ProposedViewSize(pageSize)

            renderer.render { _, draw in
                context.beginPDFPage(nil)
                draw(context)
                context.endPDFPage()
            }
        }

        context.closePDF()
        return ExportedDocument(fileURL: fileURL, title: invoice.number)
    }

    // MARK: - Helpers

    /// Splits line items into page-sized groups. Always returns at least one page.
    static func paginate(_ items: [LineItem]) -> [[LineItem]] {
        var pages = [Array(items.prefix(firstPageCapacity))]
        var remaining = items.dropFirst(firstPageCapacity)

        while !remaining.isEmpty {
            pages.append(Array(remaining.prefix(continuationPageCapacity)))
            remaining = remaining.dropFirst(continuationPageCapacity)
        }
        return pages
    }

    /// A file-system-safe name such as "INV-2026-001".
    static func fileName(for invoice: Invoice) -> String {
        let unsafeCharacters = CharacterSet(charactersIn: "/\\:?*\"<>|")
        let cleaned = invoice.number
            .components(separatedBy: unsafeCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Invoice" : cleaned
    }
}
