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
    
    @Bindable private var query: QueryManifest<BillBaseWrapper> = .init(.name);
    
    @Bindable private var billInspect = InspectionManifest<Bill>();
    @Bindable private var billDelete = DeletingManifest<Bill>();
    
    @Bindable private var utilInspect = InspectionManifest<Utility>();
    @Bindable private var utilDelete = DeletingManifest<Utility>();
    
    @Bindable private var warning = WarningManifest()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: BillsPeriod = .weekly;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @AppStorage("showExpiredBills") private var showExpiredBills: Bool = false;
    
    @Environment(\.modelContext) var modelContext;
        
    @Query private var bills: [Bill]
    @Query private var utilities: [Utility]
    
    private var sortedBills: [BillBaseWrapper] {
        query.cached
    }
    
    private func refresh() {
        var combined: [any BillBase] = bills.filter { showExpiredBills || !$0.isExpired }
        combined.append(contentsOf: utilities.filter { showExpiredBills || $0.isExpired } )
        
        query.apply(combined.map { BillBaseWrapper($0) } )
    }
    private func add_bill(_ kind: BillsKind = .bill) {
        guard kind != .utility else { return }
        
        withAnimation {
            let raw = Bill(name: "", kind: kind, amount: 0, start: Date.now, end: nil, period: .monthly)
            modelContext.insert(raw)
            refresh()
            billInspect.open(raw, mode: .edit)
        }
    }
    private func add_utility() {
        withAnimation {
            let raw = Utility("", amounts: [], start: Date.now)
            modelContext.insert(raw)
            refresh()
            utilInspect.open(raw, mode: .edit)
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
            ForEach(self.sortedBills) { wrapper in
                HStack {
                    Text(wrapper.data.name)
                    Spacer()
                    Text(wrapper.data.pricePer(showcasePeriod), format: .currency(code: currencyCode))
                    Text("/")
                    Text(showcasePeriod.perName)
                }.swipeActions(edge: .trailing) {
                    //GeneralContextMenu(bill, inspect: inspecting, remove: deleting, asSlide: true)
                }
            }
        }
    }
    @ViewBuilder
    private var wide: some View {
        Table(self.sortedBills, selection: $tableSelected) {
            TableColumn("Name", value: \.data.name)
            TableColumn("Kind") { wrapper in
                Text(wrapper.data.kind.name)
            }
            TableColumn("Amount") { wrapper in
                HStack {
                    Text(wrapper.data.amount, format: .currency(code: currencyCode))
                    Text("/")
                    Text(wrapper.data.period.perName)
                }
            }
            TableColumn("Reserved Cost") { wrapper in
                Text(wrapper.data.pricePer(showcasePeriod), format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: Bill.ID.self) { selection in
            //SelectionsContextMenu(selection, inspect: inspecting, delete: deleting, warning: warning)
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
            
            //GeneralDeleteToolbarButton(on: query.cached, selection: $tableSelected, delete: deleting, warning: warning, placement: .primaryAction)
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
            IndirectDeletingActionConfirm(deleting, action: { list in
                
            }, post: refresh)
        }.sheet(isPresented: $showingChart) {
            Chart(query.cached.sorted(by: { $0.data.amount < $1.data.amount } )) { wrapper in
                SectorMark(
                    angle: .value(
                        Text(verbatim: wrapper.data.name),
                        wrapper.data.pricePer(showcasePeriod)
                    )
                ).foregroundStyle(by: .value(
                    Text(verbatim: wrapper.data.name),
                    wrapper.data.name
                )
                )
            }.padding().frame(minHeight: 350)
        }.padding().toolbarRole(.editor).navigationTitle("Bills").onChange(of: query.hashValue, refresh).onAppear(perform: refresh)
    }
}

#Preview {
    AllBillsViewEdit().modelContainer(Containers.debugContainer)
}
