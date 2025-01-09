//
//  ContentView.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

@Observable
class MainViewVM {
    init(_ document: EdmundSQL) {
        self.ledger_vm = .init(document)
        self.balance_vm = .init(document)
    }
    
    var ledger_vm: LedgerViewerVM;
    var balance_vm: BalanceSheetVM;
}

struct MainView: View {
    @Binding var document: EdmundDocument;
    var vm: MainViewVM;
    
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink {
                    Homepage()
                } label: {
                    Label("Welcome", systemImage: "house")
                }
                NavigationLink {
                    LedgerViewer(vm: vm.ledger_vm)
                } label: {
                    Label("Ledger", systemImage: "clipboard")
                }
                NavigationLink {
                    //TransactionsView(vm: trans_vm).frame(maxHeight: .infinity)
                } label: {
                    Label("Transactions", systemImage: "pencil")
                }
                NavigationLink {
                    BalanceSheet(vm: vm.balance_vm)
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
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Homepage()
        }
    }
}

#Preview {
    var doc: EdmundDocument = .init()
    let bind: Binding<EdmundDocument> = .init(
        get: {
            doc
        },
        set: {
            doc = $0
        }
    )
    
    MainView(document: bind, vm: .init(doc.data)).frame(width: 800, height: 600)
}
