//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;
import EdmundCore;

struct LedgerTable: View {
    @Query(sort: [
        SortDescriptor(\LedgerEntry.date, order: .reverse),
        SortDescriptor(\LedgerEntry.added_on, order: .reverse)
    ]) var data: [LedgerEntry];
    
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var transKind: TransactionKind?;
    
    @Bindable private var warning: WarningManifest = .init();
    @Bindable private var inspect: InspectionManifest<LedgerEntry> = .init();
    @Bindable private var deleting: DeletingManifest<LedgerEntry> = .init();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
#if os(macOS)
    @AppStorage("preferTransWindow") private var preferTransWindow: Bool = false;
#endif
    
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
        openWindow(id: "ledger")
    }
    private func openEditor(_ kind: TransactionKind) {
        #if os(macOS)
        if preferTransWindow {
            openWindow(id: "transactionEditor", value: kind)
        }
        else {
            self.transKind = kind
        }
        #else
        self.transKind = kind
        #endif
    }
    
    @ViewBuilder
    private var compact: some View {
        List(data, selection: $selected) { entry in
            HStack {
                Text(entry.name)
                Spacer()
                Text(entry.balance, format: .currency(code: currencyCode))
            }.swipeActions(edge: .trailing) {
                SingularContextMenu(entry, inspect: inspect, remove: deleting, asSlide: true)
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
                    CompactNamedPairInspect(category)
                }
                else {
                    Text("No Category")
                }
            }
            TableColumn("Account") { item in
                if let account = item.account {
                    CompactNamedPairInspect(account)
                }
                else {
                    Text("No Account")
                }
            }
        }.contextMenu(forSelectionType: LedgerEntry.ID.self) { selection in
            SelectionContextMenu(selection, data: data, inspect: inspect, delete: deleting, warning: warning)
        }
        #if os(macOS)
        .frame(minWidth: 300)
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .view, placement: .secondaryAction)
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
                        openEditor(.simple)
                    })
                    Button(TransactionKind.composite.name, action: {
                        openEditor(.composite)
                    })
#if os(macOS)
                    Button(TransactionKind.grouped.name, action: {
                        openWindow(id: "transactionEditor", value: TransactionKind.grouped)
                    })
#endif
                    Button(TransactionKind.creditCard.name, action: {
                        openEditor(.creditCard)
                    }).disabled(true).help("futureRelease")
                } label: {
                    Text("Basic")
                }
                
                Menu {
                    Button(BillsKind.bill.name, action: {
                        openEditor(.billPay(.bill))
                    })
                    Button(BillsKind.subscription.name, action: {
                        openEditor(.billPay(.subscription))
                    })
                    Button(BillsKind.utility.name, action: {
                        openEditor(.utilityPay)
                    })
                } label: {
                    Text("Bill Payment")
                }
                
                Menu {
                    Button(TransactionKind.payday.name, action: {
                        openEditor(.payday)
                    }).disabled(true).help("futureRelease")
                    Button(TransactionKind.personalLoan.name, action: {
                        openEditor(.personalLoan)
                    })
                    
                    Button(TransactionKind.miscIncome.name, action: {
                        openEditor(.miscIncome)
                    })
                    
                    Button(TransactionKind.refund.name, action: {
                        openEditor(.refund)
                    })
                } label: {
                    Text("Income")
                }
                
                Menu {
                    Button(TransferKind.oneOne.name, action: {
                        openEditor(.transfer(.oneOne))
                    })
                    
                    Button(TransferKind.oneMany.name, action: {
                        openEditor(.transfer(.oneMany))
                    })
                    
                    Button(TransferKind.manyOne.name, action: {
                        openEditor(.transfer(.manyOne))
                    })
                    
                    Button(TransferKind.manyMany.name, action: {
                        openEditor(.transfer(.manyMany))
                    })
                } label: {
                    Text("Transfer")
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            
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
            .navigationTitle("Ledger")
            .toolbar(id: "ledgerToolbar") { toolbar }
            .toolbarRole(.editor)
            .sheet(item: $transKind) { kind in
                TransactionsEditor(kind: kind)
            }
            .sheet(item: $inspect.value) { target in
                ElementIE(target, mode: inspect.mode)
            }
            .confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting) {
                DeletingActionConfirm(deleting)
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: { warning.isPresented = false } )
            }, message: {
                Text((warning.warning ?? .noneSelected).message)
            })
    }
}

#Preview {
    LedgerTable().modelContainer(Containers.debugContainer)
}
