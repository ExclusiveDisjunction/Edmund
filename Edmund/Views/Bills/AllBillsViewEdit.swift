//
//  AllBillsEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import CoreData
import Charts
import Combine
import os

extension SortOrder {
    mutating func toggle() {
        let newValue: Self = switch self {
            case .forward: .reverse
            case .reverse: .forward
        }
        
        self = newValue
    }
}



public class BillSortingFiltering : ObservableObject {
    
    @Published public var rawSearchString: String = "";
    @Published public var searchString: String = "";
    
    
}

struct AllBillsViewEdit : View {
    @State private var showingChart: Bool = false;
    @State private var sorting = [
        SortDescriptor(\Bill.internalName, order: .forward),
        SortDescriptor(\Bill.internalKind, order: .forward),
        SortDescriptor(\Bill.internalPeriod, order: .forward)
    ]
    @State private var searchString: String = "";
    
    @FilterableQuerySelection<Bill>(filtering: { !$0.isExpired } ) private var query;
    
    @Bindable private var inspect: InspectionManifest<Bill> = .init();
    @Bindable private var deleting: DeletingManifest<Bill> = .init();
    @Bindable private var warning = SelectionWarningManifest()
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.calendar) private var calendar;
    @Environment(\.loggerSystem) private var logger;
    
    @AppStorage("showcasePeriod") private var showcasePeriod: TimePeriods = .weekly;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private var totalPPP: Decimal {
        query.data.reduce(0) { $0 + ($1.isExpired ? 0 : $1.pricePer(showcasePeriod)) }
    }
    private func toggleSort<T>(_ key: KeyPath<Bill, T>) {
        guard let index = self.sorting.firstIndex(where: { $0.keyPath == key }) else {
            logger?.data.warning("Unable to find the keypath for sorting.")
            return
        }
        self.sorting[index].order.toggle()
    }
    
    @ViewBuilder
    private var wide: some View {
        Table(context: query, sortOrder: $sorting) {
            TableColumn("Name") { wrapper in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(wrapper.name)
                        Spacer()
                        Text(wrapper.amount, format: .currency(code: currencyCode))
                        Text("/")
                        Text(wrapper.period.display)
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
                    Text(wrapper.period.display)
                }
            }
#else
            TableColumn("Amount") { wrapper in
                Text(wrapper.amount, format: .currency(code: currencyCode))
            }
            TableColumn("Frequency") { wrapper in
                Text(wrapper.period.display)
            }
#endif
            /*
            TableColumn("Next Due Date") { wrapper in
                if let date = wrapper.nextDueDate(calendar: calendar) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }
                else {
                    Text("-")
                }
            }
             */
            
            TableColumn("Set-Aside Cost") { wrapper in
                Text(
                    wrapper.isExpired ? Decimal() : wrapper.pricePer(showcasePeriod),
                    format: .currency(code: currencyCode)
                )
            }
        }.contextMenu(forSelectionType: Bill.ID.self) { selection in
            SelectionContextMenu(context: FrozenSelectionContext(data: self.query.data, selection: selection), inspect: inspect, delete: deleting, warning: warning)
        }
        .searchable(text: $searchString, prompt: "Name")
        .onChange(of: sorting) { _, sort in
            _query.configure(sortDescriptors: sorting )
        }
        .onAppear {
            _query.configure(sortDescriptors: sorting )
        }
        .onChange(of: searchString) { _, rawSearch in
            let search = rawSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            if search.isEmpty {
                _query.noPredicate()
            }
            else {
                
            }
        }
        #if os(macOS)
        .frame(minWidth: 320)
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "graph", placement: .secondaryAction) {
            Button {
                showingChart = true
            } label: {
                Label(showingChart ? "Hide Graph" : "Show Graph", systemImage: "chart.pie")
            }
        }
    
        ElementAddButton(inspect: inspect, placement: .primaryAction)
        ElementInspectButton(context: query, inspect: inspect, warning: warning, placement: horizontalSizeClass == .compact ? .secondaryAction : .primaryAction)
        ElementEditButton(context: query, inspect: inspect, warning: warning, placement: horizontalSizeClass == .compact ? .secondaryAction : .primaryAction)
        ElementDeleteButton(context: query, delete: deleting, warning: warning, placement: .primaryAction)
        
        #if os(iOS)
        ToolbarItem(id: "iosEdit", placement: .primaryAction) {
            EditButton()
        }
        #endif
    }
    
    @ViewBuilder
    private var chartView: some View {
        VStack {
            Chart(query.data.sorted(by: { $0.amount < $1.amount } )) { wrapper in
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
                Button("Ok") {
                    showingChart = false
                }.buttonStyle(.borderedProminent)
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
                        Text(period.display).tag(period)
                    }
                }
                #if os(macOS)
                .frame(width: 150)
                #endif
            }
        }.toolbar(id: "billsToolbar") {
            toolbar
        }
        .withElementIE(manifest: inspect) { bill in
            bill.name = ""
            bill.startDate = .now;
            bill.endDate = nil;
            bill.company = "";
            bill.location = nil;
            bill.period = .monthly;
            bill.kind = .bill;
            bill.history = [];
            bill.autoPay = true;
        }
        .withWarning(warning)
        .withElementDeleting(manifest: deleting)
        .sheet(isPresented: $showingChart) {
            chartView
        }.padding()
            .toolbarRole(.automatic)
            .navigationTitle("Bills")
    }
}

#Preview(traits: .sampleData) {
    AllBillsViewEdit()
}
