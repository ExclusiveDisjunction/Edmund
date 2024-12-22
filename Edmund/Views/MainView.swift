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
                    Text("Accounts")
                }
                
                NavigationLink {
                    BalanceSheet()
                } label: {
                    Text("Balance Sheet")
                }
                
                NavigationLink{
                    Spacer()
                } label: {
                    Text("Ledger")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text("Select an tab")
        }
    }
}

#Preview {
    MainView()
}
