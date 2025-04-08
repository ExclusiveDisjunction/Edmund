//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData
import Charts

struct AllBillsViewEdit : View {
    @State private var tableSelected = Set<Bill.ID>();
    @State private var showingChart: Bool = false;
    
    @Bindable private var query: QueryManifest<Bill> = .init(.name);
    @Bindable private var inspecting = InspectionManifest<Bill>();
    @Bindable private var warning = WarningManifest()
    @Bindable private var deleting = DeletingManifest<Bill>();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: BillsPeriod = .weekly;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @AppStorage("showExpiredBills") private var showExpiredBills: Bool = false;
    
    @Environment(\.modelContext) var modelContext;
        
    @Query private var bills: [Bill]
    @Query private var utilities: [Utility]
    
    private var sortedBills: [any BillBase] {
        query.cached
    }
    
    private func refresh() {
        var combined: [any BillBase] = bills.filter { showExpiredBills || !$0.isExpired }
        combined.append(contentsOf: utilities.filter { showExpiredBills || $0.isExpired } )
        
        query.apply(combined)
    }
    private func add_bill(_ kind: BillsKind = .bill) {
        withAnimation {
            let new_bill = Bill(name: "", kind: kind, amount: 0, start: Date.now, end: nil, period: .monthly)
            modelContext.insert(new_bill)
            refresh()
            inspecting.open(new_bill, mode: .edit)
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
            TableColumn("Name", value: \.name)
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
            SelectionsContextMenu(selection, inspect: inspecting, delete: deleting, warning: warning)
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
        
        GeneralInspectToolbarButton(on: query.cached, selection: $tableSelected, inspect: inspecting, warning: warning, role: .view)
        
        ToolbarItem(id: "add", placement: .primaryAction) {
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
        }
        
        if horizontalSizeClass != .compact {
            GeneralInspectToolbarButton(on: query.cached, selection: $tableSelected, inspect: inspecting, warning: warning, role: .edit, placement: .primaryAction)
            
            GeneralDeleteToolbarButton(on: query.cached, selection: $tableSelected, delete: deleting, warning: warning, placement: .primaryAction)
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
            //BillVE(bill, isEdit: inspecting.mode == .edit)
        }.toolbar(id: "billsToolbar") {
            toolbar
        }.alert("Warning", isPresented: $warning.isPresented, actions: {
            Button("Ok", action: {
                warning.isPresented = false
            })
        }, message: {
            Text((warning.warning ?? .noneSelected).message )
        }).confirmationDialog("Are you sure you want to delete these bills?", isPresented: $deleting.isDeleting) {
            DeletingActionConfirm(deleting, post: refresh)
        }.sheet(isPresented: $showingChart) {
            Chart(query.cached.sorted(by: { $0.amount < $1.amount } )) { bill in
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
        }.padding().toolbarRole(.editor).navigationTitle("Bills").onChange(of: query.hashValue, refresh).onAppear(perform: refresh)
    }
}

#Preview {
    AllBillsViewEdit().modelContainer(Containers.debugContainer)
}
