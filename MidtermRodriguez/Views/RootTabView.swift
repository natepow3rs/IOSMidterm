//
//  RootTabView.swift
//  InvoiceManager
//
//  SCREEN 1 (container): the tab bar. Each tab owns its own
//  NavigationStack so that push navigation is independent per tab.
//

import SwiftUI
import SwiftData

struct RootTabView: View {

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
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Invoice.self, Client.self, LineItem.self], inMemory: true)
}
