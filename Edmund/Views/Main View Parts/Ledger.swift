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
    
    @Bindable private var warning: WarningManifest = .init();
    @Bindable private var inspect: InspectionManifest<LedgerEntry> = .init();
    @Bindable private var deleting: DeletingManifest<LedgerEntry> = .init();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
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
    
    private func popout() {
        openWindow(id: "ledger", value: profile)
    }
    
    @ViewBuilder
    private var compact: some View {
        List(data, selection: $selected) { entry in
            HStack {
                Text(entry.memo)
                Spacer()
                Text(entry.balance, format: .currency(code: currencyCode))
            }.swipeActions(edge: .trailing) {
                GeneralContextMenu(entry, inspect: inspect, remove: deleting, asSlide: true)
            }
        }
    }
    @ViewBuilder
    private var fullSized: some View {
        Table(data, selection: $selected) {
            TableColumn("Memo", value: \.memo)
            if ledgerStyle == .none {
                TableColumn("Balance") { item in
                    Text(item.balance, format: .currency(code: currencyCode))
                }
            }
            else {
                TableColumn(ledgerStyle == .standard ? "Debit" : "Credit") { item in
                    Text(item.credit, format: .currency(code: currencyCode))
                }
                TableColumn(ledgerStyle == .standard ? "Credit" : "Debit") { item in
                    Text(item.debit, format: .currency(code: currencyCode))
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
            SelectionsContextMenu(selection, inspect: inspect, delete: deleting, warning: warning)
        }
        #if os(macOS)
        .frame(minWidth: 300)
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        if horizontalSizeClass != .compact {
            GeneralInspectToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .view, placement: .secondaryAction)
        }
        
        if shouldShowPopoutButton {
            ToolbarItem(id: "popout", placement: .secondaryAction) {
                Button(action: popout) {
                    Label("Open in new Window", systemImage: "rectangle.badge.plus")
                }
            }
        }
        
        ToolbarItem(id: "add", placement: .primaryAction) {
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
        }
    
        if horizontalSizeClass != .compact {
            GeneralInspectToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            
            GeneralDeleteToolbarButton(on: data, selection: $selected, delete: deleting, warning: warning, placement: .primaryAction)
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
            .sheet(item: $inspect.value) { target in
                VStack {
                    LedgerEntryVE(target, isEdit: inspect.mode  == .edit)
                    HStack {
                        Spacer()
                        Button("Ok") {
                            self.inspect.value = nil
                        }.buttonStyle(.borderedProminent)
                    }.padding([.trailing, .bottom])
                }
            }.alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: { warning.isPresented = false } )
            }, message: {
                Text((warning.warning ?? .noneSelected).message)
            })
    }
}

#Preview {
    var profile: String = ContainerNames.debug.name;
    let binding = Binding(get: { profile }, set: { profile = $0 })
    
    LedgerTable(profile: binding).modelContainer(Containers.debugContainer)
}
