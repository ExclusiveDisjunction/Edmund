//
//  ContentView.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    AccountsTable()
                } label: {
                    Text("Ledger")
                }
                NavigationLink {
                    VStack {
                        ManualTransactions()
                    }
                } label: {
                    Text("Transactions")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text("Welcome!")
        }
    }
}

#Preview {
    MainView()
}
