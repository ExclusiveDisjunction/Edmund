//
//  BudgetSearch.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/27/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public enum BudgetSortField : CaseIterable, Identifiable, Displayable {
    case name
    case amount
    case lastUpdated
    case lastViewed
    
    public var id: Self { self }
    
    public var display: LocalizedStringKey {
        switch self {
            case .name: "Name"
            case .amount: "Amount"
            case .lastUpdated: "Last Updated"
            case .lastViewed: "Last Viewed"
        }
    }
    
    public func sorted(data: [IncomeDividerInstance], asc: Bool) -> [IncomeDividerInstance] {
        let order: SortOrder = asc ? .forward : .reverse
        
        switch self {
            case .amount:      return data.sorted(using: KeyPathComparator(\.amount,      order: order))
            case .name:        return data.sorted(using: KeyPathComparator(\.name,        order: order))
            case .lastViewed:  return data.sorted(using: KeyPathComparator(\.lastViewed,  order: order))
            case .lastUpdated: return data.sorted(using: KeyPathComparator(\.lastUpdated, order: order))
        }
    }
}

@Observable
public class BudgetSearchCriteria: Hashable, Equatable {
    public init(query: String = "", sortBy: BudgetSortField = .name, ascending: Bool = true, hideFinalized: Bool = true) {
        self.query = query
        self.sortBy = sortBy
        self.ascending = ascending
        self.hideFinalized = hideFinalized
    }
    
    public var query: String
    public var sortBy: BudgetSortField
    public var ascending: Bool
    public var hideFinalized: Bool
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(query)
        hasher.combine(sortBy)
        hasher.combine(ascending)
    }
    
    public static func ==(lhs: BudgetSearchCriteria, rhs: BudgetSearchCriteria) -> Bool {
        lhs.query == rhs.query && lhs.sortBy == rhs.sortBy && lhs.ascending == rhs.ascending
    }
}

@Observable
public class BudgetSearchVM {
    public init() {
        
    }
    
    public var criteria: BudgetSearchCriteria = .init();
    private var _cache: [IncomeDividerInstance] = []
    
    public func update(_ data: [IncomeDividerInstance]) {
        let queryStr = self.criteria.query.trimmingCharacters(in: .whitespaces).lowercased()
        var filtered: [IncomeDividerInstance];
        if queryStr.isEmpty {
            filtered = data
        }
        else {
            filtered = data.filter { $0.query(queryStr) }
        }
        
        if criteria.hideFinalized {
            filtered = filtered.filter { !$0.isFinalized }
        }
        
        self._cache = criteria.sortBy.sorted(data: filtered, asc: criteria.ascending)
    }
    
    public var cache: [IncomeDividerInstance] {
        _cache
    }
}



struct AllBudgetsSearch : View {
    init(result: Binding<IncomeDividerInstance.ID?>) {
        self._result = result
        self.query = .init()
    }
    
    @Binding var result: IncomeDividerInstance.ID?;
    
    @Query private var budgets: [IncomeDividerInstance];
    @Bindable private var inspect: InspectionManifest<IncomeDividerInstance> = .init();
    @Bindable private var query: BudgetSearchVM
    @State private var showPopover = false;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private func contextMenuSel(_ selection: Set<IncomeDividerInstance.ID>) -> some View {
        Button {
            if let id = selection.first, let item = query.cache.first(where: { $0.id == id }), selection.count == 1 {
                inspect.open(item, mode: .inspect)
            }
        } label: {
            Label("Close Look", systemImage: "magnifyingglass")
        }.disabled(selection.count != 1)
    }
    
    @ViewBuilder
    private var fullSized: some View {
        Table(query.cache, selection: $result) {
            TableColumn("Name", value: \.name)
            if !query.criteria.hideFinalized {
                TableColumn("Finalized") { (budget: IncomeDividerInstance) in
                    Text(budget.isFinalized ? "Yes" : "No")
                }
            }
            TableColumn("Pay Amount") { budget in
                Text(budget.amount, format: .currency(code: currencyCode))
            }
            TableColumn("Deposit Account") { budget in
                CompactNamedPairInspect(budget.depositTo)
            }
#if os(macOS)
            .width(140)
#endif
            TableColumn("Last Viewed") { budget in
                Text(budget.lastViewed.formatted(date: .abbreviated, time: .shortened))
            }
#if os(macOS)
            .width(160)
#endif
            TableColumn("Last Edited") { budget in
                Text(budget.lastUpdated.formatted(date: .abbreviated, time: .shortened))
            }
#if os(macOS)
            .width(160)
#endif
        }.frame(minHeight: 250)
            .contextMenu(forSelectionType: IncomeDividerInstance.ID.self, menu: contextMenuSel)
    }
    
    @ViewBuilder
    private var compact: some View {
        List(query.cache, selection: $result) { budget in
            HStack {
                Text(budget.name)
                Spacer()
                Text(budget.amount, format: .currency(code: currencyCode))
            }.swipeActions(edge: .trailing) {
                Button {
                    inspect.open(budget, mode: .inspect)
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }
                .tint(.green)
            }
        }.frame(minHeight: 250)
            .contextMenu(forSelectionType: IncomeDividerInstance.ID.self, menu: contextMenuSel)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Budget Search")
                    .font(.title2)
                Spacer()
            }
            
            HStack {
                Text("Search:")
                TextField("", text: $query.criteria.query)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    showPopover = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }.buttonStyle(.borderless)
                    .popover(isPresented: $showPopover) {
                        Form {
                            Section {
                                Toggle("Ascending", isOn: $query.criteria.ascending)
                                Toggle("Hide Finalized", isOn: $query.criteria.hideFinalized)
                                
                                Picker("Sort By", selection: $query.criteria.sortBy) {
                                    ForEach(BudgetSortField.allCases, id: \.id) { field in
                                        Text(field.display).tag(field)
                                    }
                                }
                            }
                        }
                        #if os(iOS)
                        .frame(minWidth: 300, minHeight: 225)
                        #endif
                        .padding()
                    }
            }
            
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                fullSized
            }
            
            HStack {
                Spacer()
                
                Button("Ok", action: { dismiss() } )
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
            .onAppear {
                query.update(budgets)
            }
            .onChange(of: query.criteria.hashValue) { _, _ in
                query.update(budgets)
            }
            .sheet(item: $inspect.value) { item in
                BudgetCloseInspect(data: item)
            }
    }
}

#Preview {
    var id: UUID? = UUID();
    let binding = Binding(get: { id }, set: { id = $0 } )
    
    DebugContainerView {
        NavigationStack {
            AllBudgetsSearch(result: binding)
        }
    }
}
