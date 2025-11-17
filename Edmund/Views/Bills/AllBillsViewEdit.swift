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
    @State private var sorting =  [
        SortDescriptor(\Bill.name),
        SortDescriptor(\Bill.kind),
        SortDescriptor(\Bill.period)
    ]
    @State private var searchString: String = "";
    
    @Bindable private var query: QueryManifest<Bill> = .init(.name);
    @Bindable private var inspect: InspectionManifest<Bill> = .init();
    @Bindable private var deleting: DeletingManifest<Bill> = .init();
    @Bindable private var warning = SelectionWarningManifest()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) var modelContext;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: TimePeriods = .weekly;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Query private var bills: [Bill]
    
    public init() {
        let today = Date.now;
        let long_ago = Date.distantPast;
        _bills = Query(
            filter: #Predicate<Bill> {
                ($0.endDate ?? long_ago) < today && $0.name.caseInsensitiveCompare(searchString) == ComparisonResult.orderedAscending
            },
            sort: sorting,
        )
    }
    
    private func add(_ kind: BillsKind) {
        withAnimation {
            let raw = Bill(kind: kind);
            inspect.open(raw, mode: .add)
        }
    }
    
    private var totalPPP: Decimal {
        query.cached.reduce(0) { $0 + ($1.isExpired ? 0 : $1.pricePer(showcasePeriod)) }
    }
    
    @ViewBuilder
    private var wide: some View {
        Table(query.cached, selection: $tableSelected, sortOrder: $sorting) {
            TableColumn("Name") { wrapper in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(wrapper.name)
                        Spacer()
                        Text(wrapper.amount, format: .currency(code: currencyCode))
                        Text("/")
                        Text(wrapper.period.perName)
                    }.swipeActions(edge: .trailing) {
                        SingularContextMenu(wrapper, inspect: inspect, remove: deleting, asSlide: true)
                    }
                }
                else {
                    Text(wrapper.name)
                }
            }
            TableColumn("Kind") { wrapper in
                Text(wrapper.kind.display)
            }
            #if os(iOS)
            TableColumn("Amount") { wrapper in
                HStack {
                    Text(wrapper.amount, format: .currency(code: currencyCode))
                    Text("/")
                    Text(wrapper.period.perName)
                }
            }
            #else
            TableColumn("Amount") { wrapper in
                Text(wrapper.amount, format: .currency(code: currencyCode))
            }
            TableColumn("Frequency") { wrapper in
                Text(wrapper.period.perName)
            }
            #endif
            TableColumn("Next Due Date") { wrapper in
                if wrapper.isExpired {
                    Text("Expired Bill").italic()
                }
                else {
                    Text((wrapper.nextDueDate?.formatted(date: .abbreviated, time: .omitted) ?? "-"))
                }
            }
            
            TableColumn("Set-Aside Cost") { wrapper in
                Text((wrapper.isExpired ? Decimal() : wrapper.pricePer(showcasePeriod)), format: .currency(code: currencyCode))
            }
        }.contextMenu(forSelectionType: Bill.ID.self) { selection in
            SelectionContextMenu(selection, data: query.cached, inspect: inspect, delete: deleting, warning: warning)
        }
        .searchable(text: $searchString, prompt: "Name")
        #if os(macOS)
        .frame(minWidth: 320)
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        /*
         ToolbarItem(id: "query", placement: .secondaryAction) {
         QueryButton(provider: query)
         }
         */
        
        ToolbarItem(id: "graph", placement: .secondaryAction) {
            Button {
                showingChart = true
            } label: {
                Label(showingChart ? "Hide Graph" : "Show Graph", systemImage: "chart.pie")
            }
        }
    
        ToolbarItem(id: "add", placement: .primaryAction) {
            Menu {
                Button("Bill") {
                    add(.bill)
                }
                
                Button("Subscription") {
                    add(.subscription)
                }
                
                Button("Utility") {
                    add(.utility)
                }
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
    private var chartView: some View {
        VStack {
            Chart(query.cached.sorted(by: { $0.amount < $1.amount } )) { wrapper in
                SectorMark(
                    angle: .value(
                        Text(verbatim: wrapper.name),
                        wrapper.pricePer(showcasePeriod)
                    )
                ).foregroundStyle(by: .value(
                    Text(verbatim: wrapper.name),
                    wrapper.name
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
            ElementIE(wrapper, mode: inspect.mode)
        }.toolbar(id: "billsToolbar") {
            toolbar
        }.alert("Warning", isPresented: $warning.isPresented, actions: {
            Button("Ok") {
                warning.isPresented = false
            }
        }, message: {
            Text((warning.warning ?? .noneSelected).message )
        })
        .confirmationDialog("deleteItemsConfirm", isPresented: $deleting.isDeleting, titleVisibility: .visible) {
            DeletingActionConfirm(deleting)
        }.sheet(isPresented: $showingChart) {
            chartView
        }.padding()
            .toolbarRole(.automatic)
            .navigationTitle("Bills")
    }
}

#Preview {
    DebugContainerView {
        NavigationStack {
            AllBillsViewEdit()
        }
    }
}
