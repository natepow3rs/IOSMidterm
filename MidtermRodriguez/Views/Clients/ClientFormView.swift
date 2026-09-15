//
//  ClientFormView.swift
//  InvoiceManager
//
//  SCREEN 8: create or edit a client. Same draft-then-save pattern
//  as the invoice form.
//

import SwiftUI

struct ClientFormView: View {

    @EnvironmentObject private var store: InvoiceStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Client
    private let isNew: Bool

    init(draft: Client, isNew: Bool) {
        _draft = State(initialValue: draft)
        self.isNew = isNew
    }

    var body: some View {
        Form {
            Section("Business") {
                TextField("Company name", text: $draft.name)
                TextField("Contact person", text: $draft.contactPerson)
            }

            Section("Reach them at") {
                TextField("Email", text: $draft.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Address", text: $draft.address, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle(isNew ? "New Client" : "Edit Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!draft.isValid)
            }
        }
    }

    // MARK: - Actions

    private func save() {
        if isNew {
            store.addClient(draft)
        } else {
            store.update(draft)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ClientFormView(draft: SampleData.clients[0], isNew: false)
    }
    .environmentObject(InvoiceStore.preview)
}
