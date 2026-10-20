//
//  InvoicePDFPreviewView.swift
//  InvoiceManager
//
//  SCREEN 9: shows a generated invoice PDF and lets the user share it
//  (AirDrop, Mail, Messages, Save to Files, Print).
//

import SwiftUI

struct InvoicePDFPreviewView: View {

    @Environment(\.dismiss) private var dismiss

    let document: ExportedDocument

    var body: some View {
        PDFKitView(fileURL: document.fileURL)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: document.fileURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        if let document = try? InvoicePDFExporter.export(SampleData.invoices[0], from: .preview) {
            InvoicePDFPreviewView(document: document)
        }
    }
}
