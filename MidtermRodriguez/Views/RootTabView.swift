//
//  RootTabView.swift
//  InvoiceManager
//
//  SCREEN 1 (container): the tab bar. Each tab owns its own
//  NavigationStack so that push navigation is independent per tab.
//

import SwiftUI

struct RootTabView: View {

    @EnvironmentObject private var store: InvoiceStore

    var body: some View {
        TabView {
            NavigationStack {
                OverviewView()
            }
            .tabItem {
                Label("Overview", systemImage: "chart.bar.doc.horizontal")
            }

            NavigationStack {
                InvoiceListView()
            }
            .tabItem {
                Label("Invoices", systemImage: "doc.text")
            }

            NavigationStack {
                ClientListView()
            }
            .tabItem {
                Label("Clients", systemImage: "person.2")
            }

            NavigationStack {
                ReportsView()
            }
            .tabItem {
                Label("Reports", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { store.saveErrorMessage != nil },
                set: { if !$0 { store.saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(store.saveErrorMessage ?? "")
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(InvoiceStore.preview)
}
