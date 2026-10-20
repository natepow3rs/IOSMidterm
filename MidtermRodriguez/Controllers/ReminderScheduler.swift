//
//  ReminderScheduler.swift
//  InvoiceManager
//
//  CONTROLLER: schedules local notifications with the UserNotifications
//  framework. For each unpaid, sent invoice it plans two reminders at 9 AM:
//  the day before the due date, and the day after it (when it's overdue).
//  InvoiceStore decides which invoices need reminders and calls this.
//

import Foundation
import UserNotifications

enum ReminderScheduler {

    /// What the scheduler needs to know about one invoice.
    struct Item {
        let invoiceID: UUID
        let number: String
        let clientName: String
        let amountDue: Decimal
        let dueDate: Date
    }

    /// Reminders are delivered at this hour, local time.
    static let reminderHour = 9

    /// iOS keeps at most 64 pending notifications per app; two per invoice
    /// for the 30 nearest due dates stays well within that.
    static let maximumInvoices = 30

    // MARK: - Permission

    /// Asks iOS for permission to show notifications. Returns true if allowed.
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Replaces every pending reminder with reminders for these invoices.
    static func schedule(_ items: [Item], now: Date = Date()) async {
        cancelAll()

        let calendar = Calendar.current
        let nearest = items
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(maximumInvoices)

        for item in nearest {
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: item.dueDate) {
                await addReminder(
                    identifier: "\(item.invoiceID.uuidString)-due",
                    title: "Payment due tomorrow",
                    body: "\(item.number) for \(item.clientName): \(item.amountDue.currencyText) is due tomorrow.",
                    on: dayBefore,
                    now: now
                )
            }

            if let dayAfter = calendar.date(byAdding: .day, value: 1, to: item.dueDate) {
                await addReminder(
                    identifier: "\(item.invoiceID.uuidString)-overdue",
                    title: "Invoice overdue",
                    body: "\(item.number) for \(item.clientName) is now overdue. \(item.amountDue.currencyText) is still owed.",
                    on: dayAfter,
                    now: now
                )
            }
        }
    }

    /// Adds one reminder at `reminderHour` on the given day, skipping
    /// times that have already passed.
    private static func addReminder(
        identifier: String,
        title: String,
        body: String,
        on day: Date,
        now: Date
    ) async {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = reminderHour
        components.minute = 0

        guard let fireDate = calendar.date(from: components), fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}
