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
    //@State private var trans_vm: TransactionsViewModel = .init();
    @State private var balance_vm: BalanceSheetVM = .init();
    
    @Query private var accounts: [SubAccount];

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    Homepage()
                } label: {
                    Label("Welcome", systemImage: "house")
                }
                NavigationLink {
                    LedgerTable()
                } label: {
                    Label("Ledger", systemImage: "clipboard")
                }
                NavigationLink {
                    //TransactionsView(vm: trans_vm).frame(maxHeight: .infinity)
                } label: {
                    Label("Transactions", systemImage: "pencil")
                }
                NavigationLink {
                    BalanceSheet(vm: balance_vm)
                } label: {
                    Label("Balance Sheet", systemImage: "plus.forwardslash.minus")
                }
                NavigationLink {
                    
                } label: {
                    Label("Accounts & Categories", systemImage: "bag")
                }
                NavigationLink {
                    
                } label: {
                    Label("Paychecks", systemImage: "dollarsign.bank.building")
                }
                NavigationLink {
                    
                } label: {
                    Label("Bills", systemImage: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                }
                NavigationLink {
                    
                } label: {
                    Label("Budget", systemImage: "wand.and.sparkles")
                }
                NavigationLink {
                    
                } label: {
                    Label("Management", systemImage: "building")
                }
                
                Divider()
                
                NavigationLink {
                    VStack {
                        Button("Add Accounts", action: {
                            let accounts = Account.exampleAccounts
                            for account in accounts {
                                modelContext.insert(account)
                            }
                        })
                        
                        NamedPairPicker(on: accounts)
                    }
                } label: {
                    Label("Debug", systemImage: "")
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }
    }
}

#Preview {
    MainView().frame(width: 800, height: 600)
}
