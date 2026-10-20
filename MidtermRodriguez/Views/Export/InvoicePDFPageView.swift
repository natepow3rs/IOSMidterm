//
//  InvoicePDFPageView.swift
//  InvoiceManager
//
//  Printable layout for one page of an invoice PDF. It is never shown
//  on screen directly: InvoicePDFExporter renders it into the PDF file.
//  The page always uses a white background and light colours so it
//  prints the same in Light and Dark Mode.
//

import SwiftUI

struct InvoicePDFPageView: View {

    let invoice: Invoice
    let client: Client
    let business: BusinessProfile
    let lineItems: [LineItem]
    let amountPaid: Decimal
    let pageNumber: Int
    let pageCount: Int

    private var isFirstPage: Bool { pageNumber == 1 }
    private var isLastPage: Bool { pageNumber == pageCount }

    // Fixed print colours (they do not change with Dark Mode).
    private var ink: Color { .black }
    private var muted: Color { Color(white: 0.42) }
    private var rule: Color { Color(white: 0.86) }
    private var accent: Color { Theme.brandPrint }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isFirstPage {
                headerSection
                    .padding(.bottom, 28)
                partiesSection
                    .padding(.bottom, 24)
            } else {
                continuationHeader
                    .padding(.bottom, 20)
            }

            lineItemsTable

            if isLastPage {
                totalsSection
                    .padding(.top, 16)
                if !invoice.notes.isEmpty {
                    notesSection
                        .padding(.top, 20)
                }
            }

            Spacer(minLength: 0)
            footerSection
        }
        .padding(48)
        .frame(
            width: InvoicePDFExporter.pageSize.width,
            height: InvoicePDFExporter.pageSize.height,
            alignment: .topLeading
        )
        .background(Color.white)
        .foregroundStyle(ink)
        .environment(\.colorScheme, .light)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(business.isValid ? business.name : "Your Business Name")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accent)

                ForEach(business.contactLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 9.5))
                        .foregroundStyle(muted)
                }
            }

            Spacer(minLength: 24)

            VStack(alignment: .trailing, spacing: 6) {
                Text("INVOICE")
                    .font(.system(size: 26, weight: .heavy))
                    .tracking(2)

                Text(invoice.number)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(muted)

                statusStamp
            }
        }
    }

    @ViewBuilder
    private var statusStamp: some View {
        if invoice.status == .paid {
            stamp("PAID", color: Theme.brandPrint)
        } else if invoice.isOverdue() {
            stamp("OVERDUE", color: Color(red: 0.753, green: 0.224, blue: 0.169))
        } else if invoice.status == .draft {
            stamp("DRAFT", color: .gray)
        }
    }

    private var partiesSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                caption("BILL TO")
                    .padding(.bottom, 2)
                Text(client.name)
                    .font(.system(size: 12, weight: .semibold))
                ForEach(clientLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 9.5))
                        .foregroundStyle(muted)
                }
            }

            Spacer(minLength: 24)

            VStack(alignment: .trailing, spacing: 4) {
                detailRow("Issue date", invoice.issueDate.shortDateText)
                detailRow("Due date", invoice.dueDate.shortDateText)
                detailRow("Status", invoice.status.displayName)
            }
        }
    }

    private var continuationHeader: some View {
        HStack {
            Text(business.isValid ? business.name : "Your Business Name")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accent)
            Spacer()
            Text("\(invoice.number) (continued)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(muted)
        }
    }

    private var lineItemsTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("DESCRIPTION").frame(maxWidth: .infinity, alignment: .leading)
                Text("QTY").frame(width: 44, alignment: .trailing)
                Text("UNIT PRICE").frame(width: 92, alignment: .trailing)
                Text("AMOUNT").frame(width: 96, alignment: .trailing)
            }
            .font(.system(size: 8.5, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(accent)

            ForEach(lineItems) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text(item.details)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                    Text(item.quantity.formatted())
                        .frame(width: 44, alignment: .trailing)
                    Text(item.unitPrice.currencyText)
                        .frame(width: 92, alignment: .trailing)
                    Text(item.amount.currencyText)
                        .frame(width: 96, alignment: .trailing)
                }
                .font(.system(size: 10))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(rule).frame(height: 0.75)
                }
            }
        }
    }

    private var totalsSection: some View {
        let total = TotalsCalculator.total(of: invoice)
        let balance = max(Decimal.zero, total - amountPaid)

        return HStack {
            Spacer()
            VStack(spacing: 6) {
                totalRow("Subtotal", TotalsCalculator.subtotal(of: invoice).currencyText)
                if invoice.vatRate > 0 {
                    totalRow("VAT (\(invoice.vatRate.percentText))", TotalsCalculator.vat(of: invoice).currencyText)
                }
                totalRow("Total", total.currencyText)
                if amountPaid > 0 {
                    totalRow("Payments received", "-\(amountPaid.currencyText)")
                }

                Rectangle().fill(ink).frame(height: 1)
                    .padding(.top, 2)

                HStack {
                    Text("Balance due")
                    Spacer()
                    Text(balance.currencyText)
                }
                .font(.system(size: 13, weight: .bold))
            }
            .frame(width: 240)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            caption("NOTES")
            Text(invoice.notes)
                .font(.system(size: 9.5))
                .foregroundStyle(muted)
                .lineLimit(4)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            Rectangle().fill(rule).frame(height: 1)
            HStack {
                Text(footerMessage)
                Spacer()
                Text("Page \(pageNumber) of \(pageCount)")
            }
            .font(.system(size: 8.5))
            .foregroundStyle(muted)
        }
    }

    // MARK: - Helpers

    private var clientLines: [String] {
        [client.contactPerson, client.email, client.address].filter { !$0.isEmpty }
    }

    private var footerMessage: String {
        invoice.status == .paid
            ? "Thank you for your payment."
            : "Please settle on or before \(invoice.dueDate.shortDateText). Thank you for your business."
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8.5, weight: .bold))
            .tracking(1)
            .foregroundStyle(muted)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(title).foregroundStyle(muted)
            Text(value).fontWeight(.semibold)
        }
        .font(.system(size: 10))
    }

    private func totalRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(muted)
            Spacer()
            Text(value)
        }
        .font(.system(size: 10.5))
    }

    private func stamp(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: 1.5))
    }
}

#Preview {
    ScrollView([.horizontal, .vertical]) {
        InvoicePDFPageView(
            invoice: SampleData.invoices[0],
            client: SampleData.clients[0],
            business: SampleData.businessProfile,
            lineItems: SampleData.invoices[0].lineItems,
            amountPaid: 10000,
            pageNumber: 1,
            pageCount: 1
        )
    }
    .background(Color.gray.opacity(0.2))
}
