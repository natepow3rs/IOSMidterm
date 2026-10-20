//
//  PDFKitView.swift
//  InvoiceManager
//
//  Reusable component: UIKit's PDFView wrapped for SwiftUI so a PDF
//  file can be displayed inside any screen.
//

import SwiftUI
import UIKit
import PDFKit

struct PDFKitView: UIViewRepresentable {

    let fileURL: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .secondarySystemBackground
        pdfView.document = PDFDocument(url: fileURL)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != fileURL {
            pdfView.document = PDFDocument(url: fileURL)
        }
    }
}
