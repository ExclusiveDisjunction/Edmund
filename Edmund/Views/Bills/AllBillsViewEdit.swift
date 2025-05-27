//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData
import Charts
import EdmundCore;

struct AllBillsViewEdit : View {
    @State private var tableSelected = Set<BillBaseWrapper.ID>();
    @State private var showingChart: Bool = false;
    #if os(iOS)
    @State private var expiredBillsSheet = false;
    #endif
    
    @Bindable private var query: QueryManifest<BillBaseWrapper> = .init(.name);
    @Bindable private var inspect: InspectionManifest<BillBaseWrapper> = .init();
    @Bindable private var deleting: DeletingManifest<BillBaseWrapper> = .init();
    @Bindable private var warning = WarningManifest()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.openWindow) private var openWindow;
    
    #if os(iOS)
    private let openWindowPlacement: ToolbarItemPlacement = .topBarLeading
    #else
    private let openWindowPlacement: ToolbarItemPlacement = .automatic
    #endif
    
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
        let filteredBills = bills.filter { showExpiredBills || !$0.isExpired }
        let filteredUtilities = utilities.filter { showExpiredBills || !$0.isExpired }
        
        let combined: [any BillBase] = filteredBills + filteredUtilities;
        query.apply(combined.map { BillBaseWrapper($0) } )
    }
    private func add_bill(_ kind: BillsKind = .bill) {
        guard kind != .utility else { return }
        
        withAnimation {
            let raw = Bill(name: "", kind: kind, amount: 0, company: "",start: Date.now, end: nil, period: .monthly)
            refresh()
            inspect.open(BillBaseWrapper(raw), mode: .add)
        }
    }
    private func add_utility() {
        withAnimation {
            let raw = Utility("", amounts: [], company: "", start: Date.now)
            refresh()
            inspect.open(BillBaseWrapper(raw), mode: .add)
        }
    }
    private func toggle_inspector() {
        showingChart.toggle()
    }
    private func deleteFromModel(data: BillBaseWrapper, context: ModelContext) {
        withAnimation {
            if let bill = data.data as? Bill {
                context.delete(bill)
            }
            else if let utility = data.data as? Utility {
                context.delete(utility)
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
    private var compact: some View {
        List(self.sortedBills, selection: $tableSelected) { wrapper in
            HStack {
                Text(wrapper.data.name)
                Spacer()
                Text(wrapper.data.pricePer(showcasePeriod), format: .currency(code: currencyCode))
                Text("/")
                Text(showcasePeriod.perName)
            }.swipeActions(edge: .trailing) {
                SingularContextMenu(wrapper, inspect: inspect, remove: deleting, asSlide: true)
            }//.onTapGesture(count: 2, perform: doubleTap)
        }
    }
    @ViewBuilder
    private var wide: some View {
        Table(self.sortedBills, selection: $tableSelected) {
            TableColumn("Name", value: \.data.name)
            TableColumn("Kind") { wrapper in
                Text(wrapper.data.kind.name)
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
                    Text((wrapper.data.nextBillDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"))
                }
            }
            
            TableColumn("Set-Aside Cost") { wrapper in
                Text((wrapper.data.isExpired ? Decimal() : wrapper.data.pricePer(showcasePeriod)), format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: Bill.ID.self) { selection in
            SelectionContextMenu(selection, data: sortedBills, inspect: inspect, delete: deleting, warning: warning)
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
            Button(action: toggle_inspector) {
                Label(showingChart ? "Hide Graph" : "Show Graph", systemImage: "chart.pie")
            }
        }
        
        if !showExpiredBills {
            ToolbarItem(id: "showExpired", placement: .secondaryAction) {
                Button(action: openExpired) {
                    Label("Expired Bills", systemImage: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                }
            }
        }
        ToolbarItem(id: "refresh", placement: .secondaryAction) {
            Button(action: refresh) {
                Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
            }
        }
        ToolbarItem(id: "newWindow", placement: openWindowPlacement) {
            Button(action: {
                openWindow(id: "bills")
            }) {
                Label("Open in new Window", systemImage: "rectangle.badge.plus")
            }
        }
        
        GeneralIEToolbarButton(on: query.cached, selection: $tableSelected, inspect: inspect, warning: warning, role: .view, placement: .secondaryAction)
        
        ToolbarItem(id: "add", placement: .primaryAction) {
            Menu {
                Button("Bill", action: {
                    add_bill(.bill)
                })
                
                Button("Subscription", action: {
                    add_bill(.subscription)
                })
                
                Button("Utility", action: {
                    add_utility()
                })
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        
        GeneralIEToolbarButton(on: query.cached, selection: $tableSelected, inspect: inspect, warning: warning, role: .edit, placement: .primaryAction)
        
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
                Text("Unexpected Error").italic()
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
                Picker("", selection: $showcasePeriod) {
                    ForEach(BillsPeriod.allCases, id: \.id) { period in
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
        }).confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting) {
            AbstractDeletingActionConfirm(deleting, delete: deleteFromModel, post: refresh)
        }.sheet(isPresented: $showingChart) {
            chartView
        }.padding()
            .toolbarRole(.editor)
            .navigationTitle("Bills")
            .onChange(of: query.hashValue, refresh)
            .onChange(of: showExpiredBills, refresh)
            .onAppear(perform: refresh)
        #if os(iOS)
            .sheet(isPresented: $expiredBillsSheet) {
                billsExpiredSheet
            }
        #endif
    }
}

#Preview {
    NavigationStack {
        AllBillsViewEdit().modelContainer(Containers.debugContainer)
    }
}
