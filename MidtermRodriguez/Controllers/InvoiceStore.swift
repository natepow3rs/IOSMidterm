//
//  InvoiceStore.swift
//  InvoiceManager
//
//  CONTROLLER: owns all application data and is the only object allowed
//  to change it. Views read from it and call its methods; they never
//  mutate the arrays directly.
//

import Foundation
import Combine

final class InvoiceStore: ObservableObject {

    @Published private(set) var clients: [Client]
    @Published private(set) var invoices: [Invoice]

    init(clients: [Client] = [], invoices: [Invoice] = []) {
        self.clients = clients
        self.invoices = invoices
    }

    // MARK: - Client queries

    var sortedClients: [Client] {
        clients.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func client(withID id: Client.ID) -> Client? {
        clients.first { $0.id == id }
    }

    func clientName(for id: Client.ID) -> String {
        client(withID: id)?.name ?? "Unknown client"
    }

    // MARK: - Invoice queries

    /// Newest invoices first.
    var sortedInvoices: [Invoice] {
        invoices.sorted { $0.issueDate > $1.issueDate }
    }

    func invoice(withID id: Invoice.ID) -> Invoice? {
        invoices.first { $0.id == id }
    }

    func invoices(for clientID: Client.ID) -> [Invoice] {
        sortedInvoices.filter { $0.clientID == clientID }
    }

    /// Passing `nil` returns every invoice.
    func invoices(with status: InvoiceStatus?) -> [Invoice] {
        guard let status else { return sortedInvoices }
        return sortedInvoices.filter { $0.status == status }
    }

    func count(of status: InvoiceStatus) -> Int {
        invoices.filter { $0.status == status }.count
    }

    var recentInvoices: [Invoice] {
        Array(sortedInvoices.prefix(AppConfiguration.recentInvoiceLimit))
    }

    var overdueInvoices: [Invoice] {
        sortedInvoices.filter { $0.isOverdue() }
    }

    // MARK: - Money summaries

    /// Everything still owed to the business.
    var outstandingTotal: Decimal {
        TotalsCalculator.total(of: invoices.filter { $0.status.isOutstanding })
    }

    /// Everything already collected.
    var collectedTotal: Decimal {
        TotalsCalculator.total(of: invoices.filter { $0.status == .paid })
    }

    func billedTotal(for clientID: Client.ID) -> Decimal {
        TotalsCalculator.total(of: invoices(for: clientID))
    }

    // MARK: - Client mutations

    func addClient(_ client: Client) {
        guard client.isValid else { return }
        clients.append(client)
    }

    func update(_ client: Client) {
        guard let index = clients.firstIndex(where: { $0.id == client.id }) else { return }
        clients[index] = client
    }

    /// Removes the client and every invoice belonging to that client.
    func deleteClient(withID id: Client.ID) {
        clients.removeAll { $0.id == id }
        invoices.removeAll { $0.clientID == id }
    }

    // MARK: - Invoice mutations

    func addInvoice(_ invoice: Invoice) {
        guard invoice.isValid else { return }
        invoices.append(invoice)
    }

    func update(_ invoice: Invoice) {
        guard let index = invoices.firstIndex(where: { $0.id == invoice.id }) else { return }
        invoices[index] = invoice
    }

    func deleteInvoice(withID id: Invoice.ID) {
        invoices.removeAll { $0.id == id }
    }

    func setStatus(_ status: InvoiceStatus, forInvoiceWithID id: Invoice.ID) {
        guard let index = invoices.firstIndex(where: { $0.id == id }) else { return }
        invoices[index].status = status
    }

    // MARK: - Draft creation

    /// The next sequential document number, e.g. "INV-2026-004".
    func nextInvoiceNumber(asOf date: Date = Date()) -> String {
        let year = Calendar.current.component(.year, from: date)
        return String(format: "INV-%d-%03d", year, invoices.count + 1)
    }

    /// A blank invoice pre-filled with sensible defaults, ready to edit.
    func makeDraftInvoice() -> Invoice {
        let issueDate = Date()
        let dueDate = Calendar.current.date(
            byAdding: .day,
            value: AppConfiguration.defaultPaymentTermsInDays,
            to: issueDate
        ) ?? issueDate

        return Invoice(
            number: nextInvoiceNumber(),
            clientID: sortedClients.first?.id ?? UUID(),
            issueDate: issueDate,
            dueDate: dueDate,
            status: .draft,
            lineItems: [LineItem()]
        )
    }
}
