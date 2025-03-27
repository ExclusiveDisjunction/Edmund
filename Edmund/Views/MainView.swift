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
    @State private var trans_vm: TransactionsViewModel = .init();
    @State private var balance_vm: BalanceSheetVM = .init();

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    Homepage()
                } label: {
                    Text("Welcome")
                }
                
                NavigationLink {
                    LedgerTable()
                } label: {
                    Text("Ledger")
                }
                
                NavigationLink {
                    TransactionsView(vm: trans_vm)
                } label: {
                    Text("Transactions")
                }
                
                NavigationLink {
                    BalanceSheet(vm: balance_vm)
                } label: {
                    Text("Balance Sheet")
                }
                
                NavigationLink {
                    AllAccountsViewEdit()
                } label: {
                    Text("Accounts")
                }
                
                NavigationLink {
                    AllCategoriesViewEdit()
                } label: {
                    Text("Categories")
                }
                
                NavigationLink {
                    AllBillsViewEdit(kind: .simple)
                } label: {
                    Text("Simple Bills")
                }
                
                NavigationLink {
                    AllBillsViewEdit(kind: .complex)
                } label: {
                    Text("Complex Bills")
                }
                
                NavigationLink {
                    AllUtilitiesViewEdit()
                } label: {
                    Text("Utilities")
                }
                
                NavigationLink {
                    
                } label: {
                    Text("Budget")
                }
                NavigationLink {
                    
                } label: {
                    Text("Management")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }
    }
}

#Preview {
    MainView().frame(width: 800, height: 600).modelContainer(ModelController.previewContainer)
}
