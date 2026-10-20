//
//  InvoiceStore.swift
//  InvoiceManager
//
//  CONTROLLER: owns all application data and is the only object allowed
//  to change it. Views read from it and call its methods; they never
//  mutate the arrays directly.
//
//  Every change is written to the SwiftData database straight away, and
//  everything is loaded back from it on launch, so data survives the app
//  being closed. After every save, due-date reminders are rescheduled.
//

import Foundation
import Combine
import SwiftData

final class InvoiceStore: ObservableObject {

    @Published private(set) var clients: [Client] = []
    @Published private(set) var invoices: [Invoice] = []
    @Published private(set) var payments: [Payment] = []
    @Published private(set) var businessProfile = BusinessProfile()

    /// Whether due-date reminders are switched on (remembered between launches).
    @Published private(set) var remindersEnabled = false

    /// True when the user has refused notifications in iOS Settings.
    @Published private(set) var notificationsDenied = false

    /// Set when the last database save failed; shown to the user.
    @Published var saveErrorMessage: String?

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    private static let remindersEnabledKey = "reminders.enabled"

    init(container: ModelContainer) {
        self.container = container
        self.remindersEnabled = UserDefaults.standard.bool(forKey: Self.remindersEnabledKey)
        load()
        scheduleReminderRefresh()
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

    func invoices(matching filter: InvoiceFilter) -> [Invoice] {
        sortedInvoices.filter { filter.matches($0) }
    }

    func count(matching filter: InvoiceFilter) -> Int {
        invoices.filter { filter.matches($0) }.count
    }

    var recentInvoices: [Invoice] {
        Array(sortedInvoices.prefix(AppConfiguration.recentInvoiceLimit))
    }

    /// Overdue invoices, the longest overdue first.
    var overdueInvoices: [Invoice] {
        invoices.filter { $0.isOverdue() }.sorted { $0.dueDate < $1.dueDate }
    }

    /// True when there are no clients and no invoices saved.
    var isEmpty: Bool {
        clients.isEmpty && invoices.isEmpty
    }

    // MARK: - Payment queries

    /// Payments for one invoice, newest first.
    func payments(for invoiceID: Invoice.ID) -> [Payment] {
        payments
            .filter { $0.invoiceID == invoiceID }
            .sorted { $0.date > $1.date }
    }

    func amountPaid(for invoice: Invoice) -> Decimal {
        TotalsCalculator.sum(of: payments(for: invoice.id))
    }

    func balanceDue(for invoice: Invoice) -> Decimal {
        TotalsCalculator.balanceDue(of: invoice, payments: payments(for: invoice.id))
    }

    // MARK: - Money summaries

    /// Money clients owe right now: the unpaid balance of every sent
    /// invoice (overdue ones included). Drafts don't count until sent.
    var receivableTotal: Decimal {
        balanceTotal(of: invoices.filter { $0.status == .sent })
    }

    /// The part of `receivableTotal` that is past its due date.
    var overdueTotal: Decimal {
        balanceTotal(of: overdueInvoices)
    }

    /// Every payment ever received.
    var collectedTotal: Decimal {
        TotalsCalculator.sum(of: payments)
    }

    func billedTotal(for clientID: Client.ID) -> Decimal {
        TotalsCalculator.total(of: invoices(for: clientID))
    }

    /// What one client currently owes (balances of their sent invoices).
    func receivableTotal(for clientID: Client.ID) -> Decimal {
        balanceTotal(of: invoices(for: clientID).filter { $0.status == .sent })
    }

    func hasOverdueInvoices(for clientID: Client.ID) -> Bool {
        invoices(for: clientID).contains { $0.isOverdue() }
    }

    /// Number of this client's invoices that have not been paid yet.
    func unpaidInvoiceCount(for clientID: Client.ID) -> Int {
        invoices(for: clientID).filter { $0.status.isOutstanding }.count
    }

    private func balanceTotal(of invoices: [Invoice]) -> Decimal {
        invoices.reduce(Decimal.zero) { $0 + balanceDue(for: $1) }
    }

    // MARK: - Client mutations

    func addClient(_ client: Client) {
        guard client.isValid else { return }
        context.insert(ClientRecord(client))
        guard save() else { return }
        clients.append(client)
    }

    func update(_ client: Client) {
        guard client.isValid,
              let index = clients.firstIndex(where: { $0.id == client.id }),
              let record = clientRecord(withID: client.id)
        else { return }

        record.apply(client)
        guard save() else { return }
        clients[index] = client
    }

    /// Removes the client, every invoice belonging to that client, and
    /// the payments made on those invoices.
    func deleteClient(withID id: Client.ID) {
        let invoiceIDs = Set(invoices.filter { $0.clientID == id }.map(\.id))

        if let record = clientRecord(withID: id) {
            context.delete(record)
        }
        for record in invoiceRecords(forClientID: id) {
            context.delete(record)
        }
        for invoiceID in invoiceIDs {
            for record in paymentRecords(forInvoiceID: invoiceID) {
                context.delete(record)
            }
        }
        guard save() else { return }

        clients.removeAll { $0.id == id }
        invoices.removeAll { $0.clientID == id }
        payments.removeAll { invoiceIDs.contains($0.invoiceID) }
    }

    // MARK: - Invoice mutations

    /// Saves a new invoice. If it is created as Paid, a payment for the
    /// full amount is recorded so reports know when the money came in.
    func addInvoice(_ invoice: Invoice) {
        guard insertInvoice(invoice) else { return }
        if invoice.status == .paid {
            settleBalance(ofInvoiceWithID: invoice.id)
        }
    }

    func update(_ invoice: Invoice) {
        guard invoice.isValid,
              let index = invoices.firstIndex(where: { $0.id == invoice.id }),
              let record = invoiceRecord(withID: invoice.id)
        else { return }

        record.apply(invoice)
        record.replaceLineItems(with: invoice.lineItems, in: context)
        guard save() else { return }
        invoices[index] = invoice

        if invoice.status == .paid {
            settleBalance(ofInvoiceWithID: invoice.id)
        }
    }

    /// Removes the invoice and the payments made on it.
    func deleteInvoice(withID id: Invoice.ID) {
        if let record = invoiceRecord(withID: id) {
            context.delete(record)
        }
        for record in paymentRecords(forInvoiceID: id) {
            context.delete(record)
        }
        guard save() else { return }
        invoices.removeAll { $0.id == id }
        payments.removeAll { $0.invoiceID == id }
    }

    /// Changes the status. Marking an invoice as paid records a payment
    /// for whatever balance is left.
    func setStatus(_ status: InvoiceStatus, forInvoiceWithID id: Invoice.ID) {
        if status == .paid {
            markAsPaid(invoiceWithID: id)
        } else {
            applyStatus(status, toInvoiceWithID: id)
        }
    }

    func markAsPaid(invoiceWithID id: Invoice.ID) {
        guard let invoice = invoice(withID: id) else { return }
        if balanceDue(for: invoice) > 0 {
            settleBalance(ofInvoiceWithID: id)
        } else {
            applyStatus(.paid, toInvoiceWithID: id)
        }
    }

    // MARK: - Payment mutations

    /// Records money received. When the balance reaches zero the invoice
    /// becomes Paid automatically.
    func recordPayment(_ payment: Payment) {
        guard payment.isValid,
              let index = invoices.firstIndex(where: { $0.id == payment.invoiceID }),
              let invoiceRecord = invoiceRecord(withID: payment.invoiceID)
        else { return }

        let invoice = invoices[index]
        let remaining = balanceDue(for: invoice) - payment.amount

        var newStatus = invoice.status
        if remaining <= 0 {
            newStatus = .paid
        } else if newStatus == .draft {
            newStatus = .sent
        }

        context.insert(PaymentRecord(payment))
        invoiceRecord.statusRawValue = newStatus.rawValue
        guard save() else { return }

        payments.append(payment)
        invoices[index].status = newStatus
    }

    /// Removes a payment. A paid invoice that is no longer fully covered
    /// goes back to Sent.
    func deletePayment(withID id: Payment.ID) {
        guard let payment = payments.first(where: { $0.id == id }),
              let record = paymentRecord(withID: id)
        else { return }

        context.delete(record)

        var reopenedIndex: Int?
        if let index = invoices.firstIndex(where: { $0.id == payment.invoiceID }),
           invoices[index].status == .paid {
            let stillPaid = amountPaid(for: invoices[index]) - payment.amount
            if stillPaid < TotalsCalculator.total(of: invoices[index]) {
                invoiceRecord(withID: payment.invoiceID)?.statusRawValue = InvoiceStatus.sent.rawValue
                reopenedIndex = index
            }
        }
        guard save() else { return }

        payments.removeAll { $0.id == id }
        if let reopenedIndex {
            invoices[reopenedIndex].status = .sent
        }
    }

    // MARK: - Business profile mutations

    func updateBusinessProfile(_ profile: BusinessProfile) {
        guard profile.isValid else { return }

        if let record = businessProfileRecord() {
            record.apply(profile)
        } else {
            context.insert(BusinessProfileRecord(profile))
        }
        guard save() else { return }
        businessProfile = profile
    }

    // MARK: - Reminders

    /// Turns due-date reminders on or off. Turning them on asks iOS for
    /// permission to send notifications the first time.
    func setRemindersEnabled(_ enabled: Bool) async {
        if enabled {
            let granted = await ReminderScheduler.requestAuthorization()
            notificationsDenied = !granted
            remindersEnabled = granted
        } else {
            remindersEnabled = false
        }
        UserDefaults.standard.set(remindersEnabled, forKey: Self.remindersEnabledKey)
        await refreshReminders()
    }

    /// Replaces all scheduled reminders with ones for the current invoices.
    func refreshReminders() async {
        guard remindersEnabled else {
            ReminderScheduler.cancelAll()
            return
        }

        let items = invoices
            .filter { $0.status == .sent }
            .map { invoice in
                ReminderScheduler.Item(
                    invoiceID: invoice.id,
                    number: invoice.number,
                    clientName: clientName(for: invoice.clientID),
                    amountDue: balanceDue(for: invoice),
                    dueDate: invoice.dueDate
                )
            }
            .filter { $0.amountDue > 0 }

        await ReminderScheduler.schedule(items)
    }

    private func scheduleReminderRefresh() {
        Task { await refreshReminders() }
    }

    // MARK: - Data management

    /// Adds the demo clients, invoices and payments. Only allowed when
    /// nothing is saved yet, so the demo data never mixes with real records.
    func loadSampleData() {
        guard isEmpty else { return }
        for client in SampleData.clients {
            addClient(client)
        }
        for invoice in SampleData.invoices {
            insertInvoice(invoice)
        }
        for payment in SampleData.payments {
            recordPayment(payment)
        }
        if !businessProfile.isValid {
            updateBusinessProfile(SampleData.businessProfile)
        }
    }

    /// Permanently removes every client, invoice, payment and the business profile.
    func eraseAllData() {
        do {
            try context.delete(model: PaymentRecord.self)
            try context.delete(model: LineItemRecord.self)
            try context.delete(model: InvoiceRecord.self)
            try context.delete(model: ClientRecord.self)
            try context.delete(model: BusinessProfileRecord.self)
        } catch {
            saveErrorMessage = "Couldn't erase the data. \(error.localizedDescription)"
            return
        }
        guard save() else { return }
        load()
    }

    // MARK: - Draft creation

    /// The next sequential document number for this year, e.g. "INV-2026-004".
    /// Uses the highest existing number, so deleting an invoice never causes
    /// a duplicate.
    func nextInvoiceNumber(asOf date: Date = Date()) -> String {
        let year = Calendar.current.component(.year, from: date)
        let prefix = "INV-\(year)-"
        let highest = invoices
            .compactMap { invoice -> Int? in
                guard invoice.number.hasPrefix(prefix) else { return nil }
                return Int(invoice.number.dropFirst(prefix.count))
            }
            .max() ?? 0
        return String(format: "INV-%d-%03d", year, highest + 1)
    }

    /// A blank invoice pre-filled with sensible defaults, ready to edit.
    /// Pass a client to start the invoice for that client.
    func makeDraftInvoice(for clientID: Client.ID? = nil) -> Invoice {
        let issueDate = Date()
        let dueDate = Calendar.current.date(
            byAdding: .day,
            value: AppConfiguration.defaultPaymentTermsInDays,
            to: issueDate
        ) ?? issueDate

        return Invoice(
            number: nextInvoiceNumber(),
            clientID: clientID ?? sortedClients.first?.id ?? UUID(),
            issueDate: issueDate,
            dueDate: dueDate,
            status: .draft,
            lineItems: [LineItem()]
        )
    }

    /// A payment pre-filled with the invoice's remaining balance.
    func makeDraftPayment(for invoice: Invoice) -> Payment {
        Payment(invoiceID: invoice.id, amount: balanceDue(for: invoice))
    }

    // MARK: - Private helpers

    /// Saves an invoice without any automatic payment.
    @discardableResult
    private func insertInvoice(_ invoice: Invoice) -> Bool {
        guard invoice.isValid else { return false }
        let record = InvoiceRecord(invoice)
        context.insert(record)
        record.replaceLineItems(with: invoice.lineItems, in: context)
        guard save() else { return false }
        invoices.append(invoice)
        return true
    }

    /// Records a payment (method "Other", dated today) for whatever is left.
    private func settleBalance(ofInvoiceWithID id: Invoice.ID) {
        guard let invoice = invoice(withID: id) else { return }
        let balance = balanceDue(for: invoice)
        guard balance > 0 else { return }
        recordPayment(Payment(invoiceID: id, amount: balance, method: .other))
    }

    private func applyStatus(_ status: InvoiceStatus, toInvoiceWithID id: Invoice.ID) {
        guard let index = invoices.firstIndex(where: { $0.id == id }),
              let record = invoiceRecord(withID: id)
        else { return }

        record.statusRawValue = status.rawValue
        guard save() else { return }
        invoices[index].status = status
    }

    // MARK: - Database access

    /// Reads everything from the database into the published arrays.
    private func load() {
        do {
            clients = try context.fetch(FetchDescriptor<ClientRecord>()).map(\.value)
            invoices = try context.fetch(FetchDescriptor<InvoiceRecord>()).map(\.value)
            payments = try context.fetch(FetchDescriptor<PaymentRecord>()).map(\.value)
            businessProfile = businessProfileRecord()?.value ?? BusinessProfile()
        } catch {
            saveErrorMessage = "Couldn't load saved data. \(error.localizedDescription)"
        }
    }

    /// Writes pending changes to disk. On failure the changes are rolled back
    /// so the database and the screen stay in sync.
    @discardableResult
    private func save() -> Bool {
        do {
            try context.save()
            scheduleReminderRefresh()
            return true
        } catch {
            context.rollback()
            saveErrorMessage = "Your changes couldn't be saved. \(error.localizedDescription)"
            return false
        }
    }

    private func clientRecord(withID id: UUID) -> ClientRecord? {
        var descriptor = FetchDescriptor<ClientRecord>(predicate: #Predicate<ClientRecord> { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func invoiceRecord(withID id: UUID) -> InvoiceRecord? {
        var descriptor = FetchDescriptor<InvoiceRecord>(predicate: #Predicate<InvoiceRecord> { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func invoiceRecords(forClientID id: UUID) -> [InvoiceRecord] {
        let descriptor = FetchDescriptor<InvoiceRecord>(predicate: #Predicate<InvoiceRecord> { $0.clientID == id })
        return (try? context.fetch(descriptor)) ?? []
    }

    private func paymentRecord(withID id: UUID) -> PaymentRecord? {
        var descriptor = FetchDescriptor<PaymentRecord>(predicate: #Predicate<PaymentRecord> { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func paymentRecords(forInvoiceID id: UUID) -> [PaymentRecord] {
        let descriptor = FetchDescriptor<PaymentRecord>(predicate: #Predicate<PaymentRecord> { $0.invoiceID == id })
        return (try? context.fetch(descriptor)) ?? []
    }

    private func businessProfileRecord() -> BusinessProfileRecord? {
        try? context.fetch(FetchDescriptor<BusinessProfileRecord>()).first
    }
}
