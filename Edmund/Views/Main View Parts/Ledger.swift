//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;

struct LedgerEntryInspector: View {
    var target: LedgerEntry;
    
    #if os(macOS)
    var labelMinWidth: CGFloat = 60;
    var labelMaxWidth: CGFloat = 70;
    #else
    var labelMinWidth: CGFloat = 80;
    var labelMaxWidth: CGFloat = 85;
    #endif

    var body: some View {
        VStack {
            Text(target.memo).font(.title2)
            
            Grid {
                GridRow {
                    Text("Credit:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.credit, format: .currency(code: "USD"))
                        Spacer()
                    }
                }
                GridRow {
                    Text("Debit:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.debit, format: .currency(code: "USD"))
                        Spacer()
                    }
                }
                GridRow {
                    Text("Balance:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.balance, format: .currency(code: "USD"))
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Date:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                    }
                }
                GridRow {
                    Text("Added On:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.added_on.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Location:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(target.location)
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Category:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        
                        if let cat = target.category {
                            NamedPairViewer(pair: cat)
                        }
                        else {
                            Text("No Category")
                        }
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Account:")
                        .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    HStack {
                        if let acc = target.account {
                            NamedPairViewer(pair: acc)
                        }
                        else {
                            Text("No Account")
                        }
                        Spacer()
                    }
                }
                Divider()
            }
        
            Spacer()
        }
    }
}

struct LedgerTable: View {
    @Query(sort: \LedgerEntry.added_on, order: .reverse) var data: [LedgerEntry];
    
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var editing: LedgerEntry?;
    @State private var inspecting: LedgerEntry?;
    @State private var editAlert = false;
    @State private var showInspect = false;
    
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
    private func popout() {
        openWindow(id: "Ledger")
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                List {
                    ForEach(data) { entry in
                        HStack {
                            Text("\"\(entry.memo)\" ")
                            Text(entry.balance, format: .currency(code: "USD"))
                        }.swipeActions(edge: .trailing) {
                            Button(action: {
                                modelContext.delete(entry)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }.tint(.red)
                            
                            Button(action: {
                                editing = entry
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.blue)
                            
                            Button(action: {
                                inspecting = entry
                                showInspect = true
                            }) {
                                Label("Inspect", systemImage: "magnifyingglass")
                            }.tint(.green)
                        }
                    }
                }
            }
            else {
                Table(data, selection: $selected) {
                    TableColumn("Memo", value: \.memo)
                    if showAsBalances ?? showAsBalancesDefault  {
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
                    Button(action: {
                        showInspect.toggle()
                    }) {
                        Label(showInspect ? "Hide Inspector" : "Show Inspector", systemImage: "magnifyingglass")
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
        }.inspector(isPresented: $showInspect) {
            VStack {
                if let entry = inspecting {
                    LedgerEntryInspector(target: entry)
                }
                else if let selectedID = self.selected.first, let entry = data.first(where: {$0.id == selectedID}) {
                    LedgerEntryInspector(target: entry)
                }
                else {
                    Spacer()
                    Text("Please select a transaction to inspect it").font(.caption).italic()
                    Spacer()
                }
            }.padding().inspectorColumnWidth(min: 250, ideal: 300, max: 450)
        }
    }
}

#Preview {
    LedgerTable().modelContainer(ModelController.previewContainer)
}
