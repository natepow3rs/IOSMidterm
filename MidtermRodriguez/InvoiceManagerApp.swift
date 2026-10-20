//
//  InvoiceManagerApp.swift
//  InvoiceManager
//
//  App entry point. Opens the on-device database, creates the single
//  controller instance, and hands it to every screen through the
//  SwiftUI environment.
//

import SwiftUI

@main
struct InvoiceManagerApp: App {

    /// The one and only instance of the controller for the whole app.
    /// It loads whatever was saved the last time the app ran.
    @StateObject private var store = InvoiceStore(
        container: InvoiceDatabase.makeContainer()
    )

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
