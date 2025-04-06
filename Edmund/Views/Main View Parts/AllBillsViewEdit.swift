//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData
import Charts

struct GeneralActionsPanel: View {
    var on_add: () -> Void;
    var on_edit: () -> Void;
    var on_delete: () -> Void;
    
    var body: some View {
        HStack {
            Button(action: on_add) {
                Image(systemName: "plus")
            }
            Button(action: on_edit) {
                Image(systemName: "pencil")
            }
            Button(action: on_delete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
        }
    }
}

struct AllBillsViewEdit : View {
    @State private var query: QueryProvider<Bill> = .init(.name);
    @State private var tableSelected = Set<Bill.ID>();
    @State private var showingChart: Bool = false;
    
    @Bindable private var inspecting = InspectionManifest<Bill>();
    @Bindable private var warning = WarningManifest()
    @Bindable private var deleting = DeletingManifest<Bill>();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: BillsPeriod = .weekly;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @AppStorage("showExpiredBills") private var showExpiredBills: Bool = false;
    
    @Environment(\.modelContext) var modelContext;
        
    @Query private var bills: [Bill]
    private var sortedBills: [Bill] {
        query.apply(bills.filter { showExpiredBills || !$0.isExpired } )
    }
    
    private func add_bill(_ kind: BillsKind = .bill) {
        withAnimation {
            let new_bill = Bill(name: "", kind: kind, amount: 0, child: kind == .utility ? UtilityBridge(nil) : nil, start: Date.now, end: nil, period: .monthly)
            modelContext.insert(new_bill)
            inspecting.open(new_bill, mode: .edit)
        }
    }
    private func remove_selected() {
        let resolved = bills.filter { tableSelected.contains($0.id) }
        if resolved.count == 0 {
            warning.warning = .noneSelected
        }
        else {
            deleting.action = resolved
        }
    }
    private func edit_selected() {
        let resolved = bills.filter { tableSelected.contains($0.id) }
        if resolved.count == 0 {
            warning.warning = .noneSelected
        }
        else if let first = resolved.first {
            inspecting.open(first, mode: .edit)
        }
        else {
            warning.warning = .tooMany
        }
    }
    private func remove_specifics(_ id: Set<Bill.ID>) {
        let resolved = bills.filter { id.contains($0.id) }
        if !resolved.isEmpty {
            deleting.action = resolved
        }
    }
    private func toggle_inspector() {
        showingChart.toggle()
    }
    
    private var totalPPP: Decimal {
        bills.reduce(0, {$0 + $1.pricePer(showcasePeriod)})
    }
    
    @ViewBuilder
    private var compact: some View {
        List {
            ForEach(self.sortedBills) { bill in
                HStack {
                    Text(bill.name)
                    Spacer()
                    Text(bill.pricePer(showcasePeriod), format: .currency(code: currencyCode))
                    Text("/")
                    Text(showcasePeriod.perName)
                }.swipeActions(edge: .trailing) {
                    GeneralContextMenu(bill, inspect: inspecting, remove: deleting, asSlide: true)
                }
            }
        }
    }
    @ViewBuilder
    private var wide: some View {
        Table(self.sortedBills, selection: $tableSelected) {
            TableColumn("Name", value: \Bill.name)
            TableColumn("Kind") { bill in
                Text(bill.kind.name)
            }
            TableColumn("Amount") { bill in
                HStack {
                    Text(bill.amount, format: .currency(code: currencyCode))
                    Text("/")
                    Text(bill.period.perName)
                }
            }
            TableColumn("Reserved Cost") { bill in
                Text(bill.pricePer(showcasePeriod), format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: Bill.ID.self) { selection in
            SelectionsContextMenu(selection, inspect: inspecting, delete: deleting)
        }
        #if os(macOS)
        .frame(minWidth: 270)
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "query", placement: .secondaryAction) {
            QueryButton(provider: query)
        }
        
        ToolbarItem(id: "graph", placement: .secondaryAction) {
            Button(action: toggle_inspector) {
                Label(showingChart ? "Hide Graph" : "Show Graph", systemImage: "chart.pie")
            }
        }
        
        ToolbarItem(id: "inspect", placement: .secondaryAction) {
            Button(action: {} ) {
                Label("Inspect", systemImage: "info.circle")
            }
        }
        
        ToolbarItem(id: "general", placement: .primaryAction) {
            ControlGroup {
                Menu {
                    Button("Bill", action: {
                        add_bill(.bill)
                    })
                    
                    Button("Subscription", action: {
                        add_bill(.subscription)
                    })
                    
                    Button("Utility", action: {
                        add_bill(.utility)
                    })
                } label: {
                    Label("Add", systemImage: "plus")
                }
                
                
                if horizontalSizeClass != .compact {
                    Button(action: edit_selected) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: remove_selected) {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }
                }
            }
        }
        
        
    }

    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                wide
            }
            
            HStack {
                Spacer()
                Text("Total:")
                Text(self.totalPPP, format: .currency(code: currencyCode))
                Text("/")
                Text(showcasePeriod.perName)
                
            }
        }.sheet(item: $inspecting.value) { bill in
            BillEditor(bill: bill)
        }.toolbar(id: "billsToolbar") {
            toolbar
        }.alert("Warning", isPresented: $warning.isPresented, actions: {
            Button("Ok", action: {
                warning.isPresented = false
            })
        }, message: {
            Text((warning.warning ?? .noneSelected).message )
        }).confirmationDialog("Are you sure you want to delete these bills?", isPresented: $deleting.isDeleting) {
            DeletingActionConfirm(deleting: deleting)
        }.sheet(isPresented: $showingChart) {
            Chart(bills.sorted(by: { $0.amount < $1.amount } )) { bill in
                SectorMark(
                    angle: .value(
                        Text(verbatim: bill.name),
                        bill.pricePer(showcasePeriod)
                    )
                ).foregroundStyle(by: .value(
                    Text(verbatim: bill.name),
                    bill.name
                )
                )
            }.padding().frame(minHeight: 350)
        }.padding().toolbarRole(.editor).navigationTitle("Bills")
    }
}

#Preview {
    AllBillsViewEdit().modelContainer(Containers.debugContainer)
}
