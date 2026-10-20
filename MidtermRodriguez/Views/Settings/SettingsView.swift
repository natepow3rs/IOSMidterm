//
//  SettingsView.swift
//  InvoiceManager
//
//  SCREEN 10: the business profile printed on exported invoices,
//  due-date reminders, a read-only summary of the app's invoice
//  defaults, and data controls (load demo data, erase everything).
//
//  Like the other forms, it edits a local copy (`draft`) and only hands
//  it to the controller when Save is tapped.
//

import SwiftUI
import UIKit

struct SettingsView: View {

    @EnvironmentObject private var store: InvoiceStore

    @State private var draft = BusinessProfile()
    @State private var didLoadDraft = false
    @State private var isConfirmingErase = false

    private var hasChanges: Bool {
        draft != store.businessProfile
    }

    var body: some View {
        Form {
            businessSection
            contactSection
            remindersSection
            defaultsSection
            dataSection
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Revert") { draft = store.businessProfile }
                    .disabled(!hasChanges)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!hasChanges || !draft.isValid)
            }
        }
        .onAppear(perform: loadDraft)
        .confirmationDialog(
            "Erase all data?",
            isPresented: $isConfirmingErase,
            titleVisibility: .visible
        ) {
            Button("Erase Everything", role: .destructive, action: eraseAllData)
        } message: {
            Text("All clients, invoices, payments and business details will be permanently deleted from this device.")
        }
    }

    // MARK: - Sections

    private var businessSection: some View {
        Section {
            TextField("Business name", text: $draft.name)
            TextField("TIN (optional)", text: $draft.taxID)
                .keyboardType(.numbersAndPunctuation)
        } header: {
            Text("Business")
        } footer: {
            Text("These details appear at the top of every invoice PDF you export.")
        }
    }

    private var contactSection: some View {
        Section("Contact details") {
            TextField("Address", text: $draft.address, axis: .vertical)
                .lineLimit(1...3)

            TextField("Email", text: $draft.email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Phone", text: $draft.phone)
                .keyboardType(.phonePad)
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle("Due-date reminders", isOn: remindersBinding)

            if store.notificationsDenied {
                Label("Notifications are turned off for this app.", systemImage: "bell.slash")
                    .font(.footnote)
                    .foregroundStyle(Theme.overdue)

                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open iPhone Settings", destination: settingsURL)
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Get a notification at 9 AM the day before an unpaid invoice is due, and again the day after it becomes overdue.")
        }
    }

    /// The switch asks the controller to turn reminders on or off. Turning
    /// them on may show the iOS permission prompt.
    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { store.remindersEnabled },
            set: { isOn in
                Task { await store.setRemindersEnabled(isOn) }
            }
        )
    }

    private var defaultsSection: some View {
        Section("Invoice defaults") {
            LabeledContent("Currency", value: AppConfiguration.currencyCode)
            LabeledContent("VAT rate", value: AppConfiguration.defaultVATRate.percentText)
            LabeledContent("Payment terms", value: "\(AppConfiguration.defaultPaymentTermsInDays) days")
        }
    }

    private var dataSection: some View {
        Section {
            LabeledContent("Clients", value: "\(store.clients.count)")
            LabeledContent("Invoices", value: "\(store.invoices.count)")
            LabeledContent("Payments", value: "\(store.payments.count)")

            Button("Load sample data", action: loadSampleData)
                .disabled(!store.isEmpty)

            Button("Erase all data", role: .destructive) {
                isConfirmingErase = true
            }
            .disabled(store.isEmpty && !store.businessProfile.isValid)
        } header: {
            Text("Data")
        } footer: {
            Text("Everything is saved on this device and is still there after the app is closed. Sample data can only be loaded when the app is empty.")
        }
    }

    // MARK: - Actions

    /// Copies the saved profile into the draft the first time the tab appears.
    private func loadDraft() {
        guard !didLoadDraft else { return }
        draft = store.businessProfile
        didLoadDraft = true
    }

    private func save() {
        store.updateBusinessProfile(draft)
    }

    private func loadSampleData() {
        store.loadSampleData()
        draft = store.businessProfile
    }

    private func eraseAllData() {
        store.eraseAllData()
        draft = store.businessProfile
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(InvoiceStore.preview)
}
