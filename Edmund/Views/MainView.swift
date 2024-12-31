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
    @State private var trans_vm: TransactionsViewModel = TransactionsViewModel();

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    TransactionsTable()
                } label: {
                    Text("Ledger")
                }
                NavigationLink {
                    TransactionsView(vm: trans_vm).frame(maxHeight: .infinity)
                } label: {
                    Text("Transactions")
                }
                NavigationLink {
                    
                } label: {
                    Text("Balance Sheet")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Text("Welcome!")
        }
    }
}

#Preview {
    MainView().frame(width: 700, height: 600)
}
