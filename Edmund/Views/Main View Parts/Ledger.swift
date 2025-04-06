//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;

struct LedgerWindow : View {
    init(profile: Binding<String?>) {
        self._profileName = profile
    }
    @Binding var profileName: String?;
    
    var body: some View {
        LedgerTable(profile: Binding(
            get: { profileName ?? Containers.defaultContainerName.name },
            set: { profileName = $0 }
        ), isPopout: true)
    }
}

struct LedgerTable: View {
    @Query(sort: \LedgerEntry.added_on, order: .reverse) var data: [LedgerEntry];
    
    @Binding var profile: String;
    @State var isPopout = false;
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var inspecting: LedgerEntry?;
    @State private var inspectingMode: InspectionMode?;
    @State private var editAlert = false;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    
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
        openWindow(id: "ledger", value: profile)
    }
    
    @ViewBuilder
    private var compact: some View {
        List(data, selection: $selected) { entry in
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
    @ViewBuilder
    private var fullSized: some View {
        Table(data, selection: $selected) {
            TableColumn("Memo", value: \.memo)
            if ledgerStyle == .none {
                TableColumn("Balance") { item in
                    Text(item.balance, format: .currency(code: "USD"))
                }
            }
            else {
                TableColumn(ledgerStyle == .standard ? "Debit" : "Credit") { item in
                    Text(item.credit, format: .currency(code: "USD"))
                }
                TableColumn(ledgerStyle == .standard ? "Credit" : "Debit") { item in
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
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        if horizontalSizeClass != .compact {
            ToolbarItem(id: "inspect", placement: .secondaryAction) {
                Button(action: inspect_selected) {
                    Label("Inspect", systemImage: "info.circle")
                }
            }
        }
        
        if shouldShowPopoutButton {
            ToolbarItem(id: "popout", placement: .secondaryAction) {
                Button(action: popout) {
                    Label("Open in new Window", systemImage: "rectangle.badge.plus")
                }
            }
        }
        
        ToolbarItem(id: "general", placement: .primaryAction) {
            ControlGroup {
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
                        Label("Edit", systemImage: "pencil")
                    }.help("Edit the selected transaction")
                    
                    Button(action: remove_selected) {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }.help("Remove selected transactions")
                }
            }
        }
        
#if os(iOS)
        ToolbarItem(id: "edit", placement: .primaryAction) {
            EditButton()
        }
#endif
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                fullSized
            }
        }.padding()
            .navigationTitle(isPopout ? "Ledger for \(profile)" : "Ledger")
            .toolbar(id: "ledgerToolbar") {
                toolbar
            }
            .toolbarRole(.editor)
            .sheet(item: $inspecting) { entry in
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
    var profile: String = ContainerNames.debug.name;
    let binding = Binding(get: { profile }, set: { profile = $0 })
    
    LedgerTable(profile: binding).modelContainer(Containers.debugContainer)
}
