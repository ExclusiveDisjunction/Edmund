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
    @State private var totals: BalanceInformation = .init();
    
    @Bindable private var warning: SelectionWarningManifest = .init();
    @Bindable private var inspect: InspectionManifest<LedgerEntry> = .init();
    @Bindable private var deleting: DeletingManifest<LedgerEntry> = .init();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    @AppStorage("ledgerColumns") private var ledgerColumns: TableColumnCustomization<LedgerEntry>;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @AppStorage("showLedgerFooter") private var showLedgerFooter: Bool = true;
    
    private func popout() {
        openWindow(id: "ledger")
    }
    
    @ViewBuilder
    private var fullSized: some View {
        Table(data, selection: $selected, columnCustomization: $ledgerColumns) {
            TableColumn("Memo") { entry in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(entry.name)
                        Spacer()
                        Text(entry.balance, format: .currency(code: currencyCode))
                    }.swipeActions(edge: .trailing) {
                        SingularContextMenu(entry, inspect: inspect, remove: deleting, asSlide: true)
                    }
                }
                else {
                    Text(entry.name)
                }
            }
                .width(min: 120, ideal: 160, max: nil)
            
            TableColumn("Money In") { item in
                Text(item.credit, format: .currency(code: currencyCode))
            }
                .width(min: 65, ideal: 75, max: nil)
                .customizationID("moneyIn")
                .alignment(.numeric)
            
            TableColumn("Money Out") { item in
                Text(item.debit, format: .currency(code: currencyCode))
            }
                .width(min: 65, ideal: 75, max: nil)
                .customizationID("moneyOut")
                .alignment(.numeric)
            
            TableColumn("Balance") { item in
                Text(item.balance, format: .currency(code: currencyCode))
            }
                .width(min: 60, ideal: 70, max: nil)
                .customizationID("balance")
                .alignment(.numeric)
                .defaultVisibility(.hidden)
            
            TableColumn("Date") { item in
                #if os(iOS)
                Text(item.date.formatted(date: .numeric, time: .omitted))
                #else
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                #endif
            }
                .width(min: 100, ideal: 120, max: nil)
                .customizationID("date")
            
            TableColumn("Added On") { item in
#if os(iOS)
                Text(item.addedOn.formatted(date: .numeric, time: .shortened))
#else
                Text(item.addedOn.formatted(date: .abbreviated, time: .shortened))
#endif
            }
                .width(min: 100, ideal: 120, max: nil)
                .customizationID("addedOn")
                .defaultVisibility(.hidden)
            
            TableColumn("Location", value: \.location)
                .width(min: 140, ideal: 170, max: nil)
                .customizationID("location")
            
            TableColumn("Category") { item in
                ElementDisplayer(value: item.category)
            }
                .width(min: 100, ideal: 140, max: nil)
                .customizationID("category")
            
            TableColumn("Account") { item in
                ElementDisplayer(value: item.account)
            }
                .width(min: 100, ideal: 140, max: nil)
                .customizationID("account")
        }.contextMenu(forSelectionType: LedgerEntry.ID.self) { selection in
            SelectionContextMenu(selection, data: data, inspect: inspect, delete: deleting, warning: warning)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        TopicToolbarButton("Help/Ledger/Ledger.md", placement: .secondaryAction)
        
        ToolbarItem(placement: .primaryAction) {
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
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
#endif
    }
    
    var body: some View {
        VStack {
            fullSized
            
            if showLedgerFooter {
                HStack {
                    Spacer()
                    
                    Text("Total Credit:")
                    Text(totals.credit, format: .currency(code: currencyCode))
                    
                    Text("Total Debits:")
                    Text(totals.debit, format: .currency(code: currencyCode))
                    
                    Text("Total Balance:")
                        .bold()
                    Text(totals.balance, format: .currency(code: currencyCode))
                        .bold()
                }
            }
        }.padding()
            .navigationTitle("Ledger")
            .toolbar { toolbar }
            .toolbarRole(.editor)
            .onChange(of: selected) { _, new in
                self.totals = data.filter { new.contains($0.id) }.reduce(BalanceInformation()) { $0 + BalanceInformation(credit: $1.credit, debit : $1.debit) }
            }
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
