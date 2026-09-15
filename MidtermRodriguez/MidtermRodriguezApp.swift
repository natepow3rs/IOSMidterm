//
//  MidtermRodriguezApp.swift
//  MidtermRodriguez
//
//  Created by Mac-LAB on 9/15/26.
//

import SwiftUI

@main
struct InvoiceManagerApp: App {

    /// The one and only instance of the controller for the whole app.
    @StateObject private var store = InvoiceStore(
        clients: SampleData.clients,
        invoices: SampleData.invoices
    )

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
