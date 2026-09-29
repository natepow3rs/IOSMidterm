//
//  MidtermRodriguezApp.swift
//  MidtermRodriguez
//
//  Created by Mac-LAB on 9/15/26.
//

import SwiftUI
import SwiftData

@main
struct InvoiceManagerApp: App {

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        // SwiftData: create the persistent container for Invoice, Client, and LineItem models.
        // This makes a ModelContext available to every view through the
        // environment, enabling persistent storage for the invoice system.
        .modelContainer(for: [Invoice.self, Client.self, LineItem.self])
    }
}
