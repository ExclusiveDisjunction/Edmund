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
    @AppStorage("enableTransactions") var enableTransactions: Bool?;
    //@State private var trans_vm: TransactionsViewModel = .init();
    @State private var balance_vm: BalanceSheetVM = .init();

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    Homepage()
                } label: {
                    Text("Welcome")
                }
                
                if enableTransactions ?? true {
                    NavigationLink {
                        LedgerTable()
                    } label: {
                        Text("Ledger")
                    }
                    
                    NavigationLink {
                        BalanceSheet(vm: balance_vm)
                    } label: {
                        Text("Balance Sheet")
                    }
                    
                    NavigationLink {
                        AllNamedPairViewEdit<Account>()
                    } label: {
                        Text("Accounts")
                    }
                    
                    NavigationLink {
                        AllNamedPairViewEdit<Category>()
                    } label: {
                        Text("Categories")
                    }
                }
                
                NavigationLink {
                    AllBillsViewEdit()
                } label: {
                    Text("Bills")
                }
                
                NavigationLink {
                    
                } label: {
                    Text("Budget")
                }
                
#if os(iOS)
                NavigationLink {
                    SettingsView().navigationTitle("Settings")
                } label: {
                    Text("Settings")
                }
#endif
        }.navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }
    }
}

#Preview {
    MainView().frame(width: 800, height: 600).modelContainer(Containers.previewContainer)
}
