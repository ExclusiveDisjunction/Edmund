//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;

struct LedgerTable: View {
    @Query(sort: \LedgerEntry.added_on, order: .reverse) var data: [LedgerEntry];
    
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var inspecting: LedgerEntry?;
    @State private var inspectingMode: InspectionMode?;
    @State private var editAlert = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showAsBalances") private var showAsBalances: Bool?;
    
    private var shouldShowPopoutButton: Bool {
#if os(macOS)
        return true
#else
        if #available(iOS 16.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        return false
#endif
    }
    
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
            
            launchInspector(self.data.first( where: {$0.id == first } ), .edit)
        }
        else {
            editAlert = true
        }
        
    }
    private func inspect_selected() {
        let resolved = data.filter { selected.contains($0.id ) }
        
        if resolved.count == 1 {
            let first = self.selected.first!;
            launchInspector(self.data.first( where: {$0.id == first } ), .view)
        }
        else {
            editAlert = true
        }
    }
    private func launchInspector(_ target: LedgerEntry?, _ mode: InspectionMode) {
        if let target = target {
            inspectingMode = mode
            inspecting = target
        }
        else {
            inspectingMode = nil
            inspecting = nil
        }
    }
    
    private func popout() {
        openWindow(id: "Ledger")
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                List {
                    ForEach(data) { entry in
                        HStack {
                            Text(entry.memo)
                            Spacer()
                            Text(entry.balance, format: .currency(code: "USD"))
                        }.swipeActions(edge: .trailing) {
                            Button(action: {
                                launchInspector(entry, .view)
                            }) {
                                Label("Inspect", systemImage: "info.circle")
                            }.tint(.green)
                            
                            Button(action: {
                                launchInspector(entry, .edit)
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.blue)
                            
                            Button(action: {
                                modelContext.delete(entry)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                            
                            
                        }
                    }
                }
            }
            else {
                Table(data, selection: $selected) {
                    TableColumn("Memo", value: \.memo)
                    if showAsBalances ?? true  {
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
                    TableColumn("Account") { item in
                        if let account = item.account {
                            NamedPairViewer(pair: account)
                        }
                        else {
                            Text("No Account")
                        }
                    }
                }.contextMenu(forSelectionType: LedgerEntry.ID.self) { selection in
                    if selection.count == 1 {
                        let first = selection.first!
                        Button(action: {
                            launchInspector(data.first(where: {$0.id == first}), .edit)
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
                #if os(macOS)
                .frame(minWidth: 300)
                #endif
            }
        }.padding()
        .navigationTitle("Ledger")
        .toolbar {
            ToolbarItemGroup {
                if shouldShowPopoutButton {
                    Button(action: popout) {
                        Label("Open in another Window", systemImage: "square.on.square.dashed")
                    }
                }
                
                if horizontalSizeClass != .compact {
                    Button(action: inspect_selected) {
                        Label("Inspect", systemImage: "info.circle")
                    }
                }
                
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
                
                if horizontalSizeClass != .compact {
                    Button(action: edit_selected) {
                        Label("Enact", systemImage: "pencil")
                    }.help("Edit the selected transaction")
                    
                    Button(action: remove_selected) {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }.help("Remove selected transactions")
                }
            }
        }.sheet(item: $inspecting) { entry in
            VStack {
                LedgerEntryVE(entry, isEdit: inspectingMode ?? .view == .edit)
                HStack {
                    Spacer()
                    Button("Ok") {
                        inspecting = nil
                    }.buttonStyle(.borderedProminent)
                }.padding([.trailing, .bottom])
            }
        }
    }
}

#Preview {
    LedgerTable().modelContainer(ModelController.previewContainer)
}
