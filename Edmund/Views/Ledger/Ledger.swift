//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;
import EdmundCore

struct LedgerTable: View {
    @Query(sort: [
        SortDescriptor(\LedgerEntry.date, order: .reverse),
        SortDescriptor(\LedgerEntry.addedOn, order: .reverse)
    ]) var data: [LedgerEntry];
    
    @State private var selected = Set<LedgerEntry.ID>();
    @State private var transKind: TransactionKind?;
    
    @Bindable private var warning: SelectionWarningManifest = .init();
    @Bindable private var inspect: InspectionManifest<LedgerEntry> = .init();
    @Bindable private var deleting: DeletingManifest<LedgerEntry> = .init();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func popout() {
        openWindow(id: "ledger")
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
#if os(macOS)
                .width(200)
#endif
            
            TableColumn(ledgerStyle.displayCredit) { item in
                Text(item.credit, format: .currency(code: currencyCode))
            }
            TableColumn(ledgerStyle.displayDebit) { item in
                Text(item.debit, format: .currency(code: currencyCode))
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
#if os(macOS)
            .width(200)
#endif
            TableColumn("Account") { item in
                if let account = item.account {
                    CompactNamedPairInspect(account)
                }
                else {
                    Text("No Account")
                }
            }
#if os(macOS)
            .width(200)
#endif
        }.contextMenu(forSelectionType: LedgerEntry.ID.self) { selection in
            SelectionContextMenu(selection, data: data, inspect: inspect, delete: deleting, warning: warning)
        }
#if os(macOS)
        .frame(minWidth: 300)
#endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        TopicToolbarButton("Help/Ledger/Ledger.md", placement: .secondaryAction)
        
        ToolbarItem(id: "add", placement: .primaryAction) {
            TransactionMenu(selection: $transKind) {
                Label("Add", systemImage: "plus")
            }
        }
    
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            
            GeneralIEToolbarButton(on: data, selection: $selected, inspect: inspect, warning: warning, role: .inspect, placement: .primaryAction)
        }
        
        GeneralDeleteToolbarButton(on: data, selection: $selected, delete: deleting, warning: warning, placement: .primaryAction)
        
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
            .confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting, titleVisibility: .visible) {
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
    DebugContainerView {
        LedgerTable()
    }
}
