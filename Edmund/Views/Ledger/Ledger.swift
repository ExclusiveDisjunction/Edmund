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
    
    @State var isPopout: Bool = false;
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var transMode: TransactionKind?;
    
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
                Text(entry.name)
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
            TableColumn("Memo", value: \.name)
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
            SelectionsContextMenu(selection, data: data, inspect: inspect, delete: deleting, warning: warning)
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
                Menu {
                    Button(TransactionKind.simple.name, action: {
                        transMode = .simple
                    })
                    Button(TransactionKind.composite.name, action: {
                        transMode = .composite
                    })
                    Button(TransactionKind.grouped.name, action: {
                        transMode = .grouped
                    })
                    Button(TransactionKind.creditCard.name, action: {
                        transMode = .creditCard
                    })
                } label: {
                    Text("Basic")
                }
                
                Menu {
                    Button(BillsKind.bill.name, action: {
                        transMode = .billPay(.bill)
                    })
                    Button(BillsKind.subscription.name, action: {
                        transMode = .billPay(.subscription)
                    })
                    Button(BillsKind.utility.name, action: {
                        transMode = .billPay(.utility)
                    })
                } label: {
                    Text("Bill Payment")
                }
                
                Button(TransactionKind.income.name, action: {
                    transMode = .income
                })
                
                Menu {
                    Button(TransferKind.oneOne.name, action: {
                        transMode = .transfer(.oneOne)
                    })
                    
                    Button(TransferKind.oneMany.name, action: {
                        transMode = .transfer(.oneMany)
                    })
                    
                    Button(TransferKind.manyOne.name, action: {
                        transMode = .transfer(.manyOne)
                    })
                    
                    Button(TransferKind.manyMany.name, action: {
                        transMode = .transfer(.manyMany)
                    })
                } label: {
                    Text("Transfer")
                }
                
                Menu {
                    Button(TransactionKind.personalLoan.name, action: {
                        transMode = .personalLoan
                    })
                    
                    Button(TransactionKind.refund.name, action: {
                        transMode = .refund
                    })
                } label: {
                    Text("Miscellaneous")
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    
        if horizontalSizeClass != .compact {
            GeneralInspectToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            
            GeneralDeleteToolbarButton(on: data, selection: $selected, delete: deleting, warning: warning, placement: .primaryAction)
        }
        
#if os(iOS)
        ToolbarItem(id: "editIOS", placement: .primaryAction) {
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
                    LedgerEntryIE(target, mode: inspect.mode)
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
            }).sheet(item: $transMode, onDismiss: { transMode = nil }) { mode in
                TransactionEditor(kind: mode).environment(\.categoriesContext, CategoriesContext(modelContext))
            }.confirmationDialog("Are you sure you want to delete these items?", isPresented: $deleting.isDeleting) {
                DeletingActionConfirm(deleting)
            }
    }
}

#Preview {
    var profile: String = ContainerNames.debug.name;
    let binding = Binding(get: { profile }, set: { profile = $0 })
    
    LedgerTable(profile: binding).modelContainer(Containers.debugContainer)
}
