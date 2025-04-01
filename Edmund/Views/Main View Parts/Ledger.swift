//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;

struct LedgerTable: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @AppStorage("showAsBalances") private var showAsBalances: Bool?;
    @Query(sort: \LedgerEntry.added_on, order: .reverse) var data: [LedgerEntry];
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var editing: LedgerEntry?;
    @State private var editAlert = false;
    
    @Environment(\.modelContext) private var modelContext;
    
#if os(macOS)
    private let showAsBalancesDefault = false
#else
    private let showAsBalancesDefault = true
#endif
    
    private func remove_spec(_ id: Set<LedgerEntry.ID>) {
        let targets = data.filter { id.contains($0.id ) }
        for target in targets {
            modelContext.delete(target)
        }
    }
    private func remove_selected() {
        remove_spec(self.selected)
    }
    private func edit_selected() {
        if selected.count == 1 {
            let first = self.selected.first!;
            
            editing = self.data.first( where: {$0.id == first } )
        }
        else {
            editAlert = true
        }
        
    }
    
    var body: some View {
        Table(data, selection: $selected) {
            TableColumn("Memo", value: \.memo)
            if showAsBalances ?? showAsBalancesDefault || horizontalSizeClass == .compact {
                TableColumn("Balance") { item in
                    Text(item.balance, format: .currency(code: "USD"))
                }
            }
            else {
                TableColumn("Credits") { item in
                    Text(item.credit, format: .currency(code: "USD"))
                }
                TableColumn("Debits") { item in
                    Text(item.debit, format: .currency(code: "USD"))
                }
            }
            
            if horizontalSizeClass != .compact {
                TableColumn("Date") { item in
                    Text(item.date, style: .date)
                }
                TableColumn("Location", value: \.location)
                TableColumn("Category") { item in
                    if let category = item.category {
                        NamedPairViewer(pair: category)
                    }
                    else {
                        Text("No Category")
                    }
                }
            }
            TableColumn("Account") { item in
                if let account = item.account {
                    NamedPairViewer(pair: account)
                }
                else {
                    Text("No Account")
                }
            }
        }.padding()
        .contextMenu(forSelectionType: LedgerEntry.ID.self) { selection in
            if selection.count == 1 {
                let first = selection.first!
                Button(action: {
                    editing = data.first(where: {$0.id == first})
                }) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            Button(role: .destructive) {
                remove_spec(selection)
            } label: {
                Label("Delete", systemImage: "trash").foregroundStyle(.red)
            }
            
        }
        .navigationTitle("Ledger")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Text("Basic")
                    Button("Manual Transactions", action: {
                        //vm.sub_trans.append(.init(.manual()))
                    } )
                    Button("Composite Transaction", action: {
                        //vm.sub_trans.append( .init( .composite() ) )
                    })
                    Button("Bill Payment", action: {
                       //vm.sub_trans.append(.init(.bill_pay()))
                    })
                    Button("Personal Loan", action: {
                        //vm.sub_trans.append(.init(.personal_loan()))
                    })
                    
                    Divider()
                    
                    Text("Account Control")
                    Button("General Income", action: {
                        //vm.sub_trans.append(.init(.generalIncome()))
                    }).help("Gift or Interest")
                    Button("Payday", action: {
                        //vm.sub_trans.append( .init( .payday() ) )
                    }).help("Takes in a paycheck, and allows for easy control of moving money to specific accounts")
                    Button(action: {
                        //vm.sub_trans.append(.init(.audit()))
                    }) {
                        Text("Audit").foregroundStyle(Color.red)
                    }
                    
                    Divider()
                    
                    Text("Grouped")
                    Button("Credit Card Transactions", action: {
                        //vm.sub_trans.append( .init( .creditCardTrans() ) )
                    }).help("Records transactions for a specific credit card, and automatically moves money in a specified account to a designated sub-account")
                    
                    Divider()
                    
                    Text("Transfer")
                    Button("One-to-One", action: {
                        //vm.sub_trans.append( .init( .one_one_transfer() ) )
                    })
                    Button("One-to-Many", action: {
                        //vm.sub_trans.append( .init( .one_many_transfer() ) )
                    })
                    Button("Many-to-One", action: {
                        //vm.sub_trans.append( .init( .many_one_transfer() ) )
                    })
                    Button("Many-to-Many", action: {
                        //vm.sub_trans.append( .init( .many_many_transfer() ) )
                    })
                    
                } label: {
                    Label("Add", systemImage: "plus")
                }.help("Add a specific kind of transaction to the editor")
                
                Button(action: edit_selected) {
                    Label("Enact", systemImage: "pencil")
                }.help("Edit the selected transaction")
                
                Button(action: remove_selected) {
                    Label("Delete", systemImage: "trash").foregroundStyle(.red)
                }.help("Remove selected transactions")
            }
        }
    }
}

#Preview {
    LedgerTable().modelContainer(ModelController.previewContainer)
}
