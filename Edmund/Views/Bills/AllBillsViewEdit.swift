//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData
import Charts
import EdmundCore

struct AllBillsViewEdit : View {
    @State private var tableSelected = Set<BillBaseWrapper.ID>();
    @State private var showingChart: Bool = false;
    #if os(iOS)
    @State private var expiredBillsSheet = false;
    #endif
    
    @Bindable private var query: QueryManifest<BillBaseWrapper> = .init(.name);
    @Bindable private var inspect: InspectionManifest<BillBaseWrapper> = .init();
    @Bindable private var deleting: DeletingManifest<BillBaseWrapper> = .init();
    @Bindable private var warning = SelectionWarningManifest()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) var modelContext;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: TimePeriods = .weekly;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Query private var bills: [Bill]
    @Query private var utilities: [Utility]
    
    private func refresh() {
        let filteredBills = bills.filter { !$0.isExpired }
        let filteredUtilities = utilities.filter { !$0.isExpired }
        
        let combined: [any BillBase] = filteredBills + filteredUtilities;
        query.apply(combined.map { BillBaseWrapper($0) } )
    }
    private func addBill(_ kind: StrictBillsKind = .bill) {
        withAnimation {
            let raw = Bill(name: "", kind: kind, amount: 0, company: "", location: nil, start: Date.now, end: nil, period: .monthly)
            refresh()
            inspect.open(BillBaseWrapper(raw), mode: .add)
        }
    }
    private func addUtility() {
        withAnimation {
            let raw = Utility("", amounts: [], company: "", start: Date.now)
            refresh()
            inspect.open(BillBaseWrapper(raw), mode: .add)
        }
    }
    private func deleteFromModel(data: BillBaseWrapper, context: ModelContext) {
        withAnimation {
            if let bill = data.data as? Bill {
                context.delete(bill)
                Task {
                    await uniqueEngine.releaseId(key: Bill.objId, id: bill.id)
                }
            }
            else if let utility = data.data as? Utility {
                context.delete(utility)
                Task {
                    await uniqueEngine.releaseId(key: Utility.objId, id: utility.id)
                }
            }
        }
    }
    private func openExpired() {
        #if os(iOS)
        expiredBillsSheet = true
        #else
        openWindow(id: "expiredBills")
        #endif
    }
    
    private var totalPPP: Decimal {
        query.cached.reduce(0) { $0 + ($1.data.isExpired ? 0 : $1.data.pricePer(showcasePeriod)) }
    }
    
    @ViewBuilder
    private var wide: some View {
        Table(query.cached, selection: $tableSelected) {
            TableColumn("Name") { wrapper in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(wrapper.data.name)
                        Spacer()
                        Text(wrapper.data.amount, format: .currency(code: currencyCode))
                        Text("/")
                        Text(wrapper.data.period.perName)
                    }.swipeActions(edge: .trailing) {
                        SingularContextMenu(wrapper, inspect: inspect, remove: deleting, asSlide: true)
                    }
                }
                else {
                    Text(wrapper.data.name)
                }
            }
            TableColumn("Kind") { wrapper in
                Text(wrapper.data.kind.display)
            }
            #if os(iOS)
            TableColumn("Amount") { wrapper in
                HStack {
                    Text(wrapper.data.amount, format: .currency(code: currencyCode))
                    Text("/")
                    Text(wrapper.data.period.perName)
                }
            }
            #else
            TableColumn("Amount") { wrapper in
                Text(wrapper.data.amount, format: .currency(code: currencyCode))
            }
            TableColumn("Frequency") { wrapper in
                Text(wrapper.data.period.perName)
            }
            #endif
            TableColumn("Next Due Date") { wrapper in
                if wrapper.data.isExpired {
                    Text("Expired Bill").italic()
                }
                else {
                    Text((wrapper.data.nextDueDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"))
                }
            }
            
            TableColumn("Set-Aside Cost") { wrapper in
                Text((wrapper.data.isExpired ? Decimal() : wrapper.data.pricePer(showcasePeriod)), format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: BillBaseWrapper.ID.self) { selection in
            SelectionContextMenu(selection, data: query.cached, inspect: inspect, delete: deleting, warning: warning)
        }
        #if os(macOS)
        .frame(minWidth: 320)
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "query", placement: .secondaryAction) {
            QueryButton(provider: query)
        }
        
        ToolbarItem(id: "graph", placement: .secondaryAction) {
            Button {
                showingChart = true
            } label: {
                Label(showingChart ? "Hide Graph" : "Show Graph", systemImage: "chart.pie")
            }
        }
        
        ToolbarItem(id: "refresh", placement: .secondaryAction) {
            Button(action: refresh) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
        }
    
        ToolbarItem(id: "add", placement: .primaryAction) {
            Menu {
                Button("Bill", action: {
                    addBill(.bill)
                })
                
                Button("Subscription", action: {
                    addBill(.subscription)
                })
                
                Button("Utility", action: {
                    addUtility()
                })
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        
        if horizontalSizeClass != .compact {
            GeneralIEToolbarButton(on: query.cached, selection: $tableSelected, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
            GeneralIEToolbarButton(on: query.cached, selection: $tableSelected, inspect: inspect, warning: warning, role: .inspect, placement: .primaryAction)
        }
        
        GeneralDeleteToolbarButton(on: query.cached, selection: $tableSelected, delete: deleting, warning: warning, placement: .primaryAction)
        
        #if os(iOS)
        ToolbarItem(id: "iosEdit", placement: .primaryAction) {
            EditButton()
        }
        #endif
    }

    @ViewBuilder
    private func inspectSheet(_ wrapper: BillBaseWrapper) -> some View {
        if let asBill = wrapper.data as? Bill {
            ElementIE(asBill, mode: inspect.mode, postAction: refresh)
        }
        else if let asUtility = wrapper.data as? Utility {
            ElementIE(asUtility, mode: inspect.mode, postAction: refresh)
        }
        else {
            VStack {
                Text("internalError").italic()
                Button("Ok", action: {
                    inspect.value = nil
                }).buttonStyle(.borderedProminent)
            }
        }
    }
    
    #if os(iOS)
    @ViewBuilder
    private var billsExpiredSheet: some View {
        NavigationStack {
            AllExpiredBillsVE()
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { expiredBillsSheet = false } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
    #endif
    
    @ViewBuilder
    private var chartView: some View {
        VStack {
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
            }.frame(minHeight: 350)
            
            HStack {
                Spacer()
                Button("Ok", action: { showingChart = false } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
    
    var body: some View {
        VStack {
            wide
            
            HStack {
                Spacer()
                Text("Total:")
                Text(self.totalPPP, format: .currency(code: currencyCode))
                Text("/")
                Picker("", selection: $showcasePeriod) {
                    ForEach(TimePeriods.allCases, id: \.id) { period in
                        Text(period.perName).tag(period)
                    }
                }
                #if os(macOS)
                .frame(width: 150)
                #endif
            }
        }.sheet(item: $inspect.value) { wrapper in
            inspectSheet(wrapper)
        }.toolbar(id: "billsToolbar") {
            toolbar
        }.alert("Warning", isPresented: $warning.isPresented, actions: {
            Button("Ok", action: {
                warning.isPresented = false
            })
        }, message: {
            Text((warning.warning ?? .noneSelected).message )
        }).confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting, titleVisibility: .visible) {
            AbstractDeletingActionConfirm(deleting, delete: deleteFromModel, post: refresh)
        }.sheet(isPresented: $showingChart) {
            chartView
        }.padding()
            .toolbarRole(.automatic)
            .navigationTitle("Bills")
            .onChange(of: query.hashValue, refresh)
            .onAppear {
                refresh()
            }
        #if os(iOS)
            .sheet(isPresented: $expiredBillsSheet) {
                billsExpiredSheet
            }
        #endif
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    NavigationStack {
        AllBillsViewEdit()
    }
}
