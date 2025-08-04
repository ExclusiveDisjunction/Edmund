//
//  BudgetSearch.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/27/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public enum IncomeDividerSortField : CaseIterable, Identifiable, Displayable {
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
    
    public func sorted(data: [IncomeDivision], asc: Bool) -> [IncomeDivision] {
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
public class IncomeDividerSearchCriteria: Hashable, Equatable {
    public init(query: String = "", sortBy: IncomeDividerSortField = .name, ascending: Bool = true, hideFinalized: Bool = true) {
        self.query = query
        self.sortBy = sortBy
        self.ascending = ascending
        self.hideFinalized = hideFinalized
    }
    
    public var query: String
    public var sortBy: IncomeDividerSortField
    public var ascending: Bool
    public var hideFinalized: Bool
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(query)
        hasher.combine(sortBy)
        hasher.combine(ascending)
    }
    
    public static func ==(lhs: IncomeDividerSearchCriteria, rhs: IncomeDividerSearchCriteria) -> Bool {
        lhs.query == rhs.query && lhs.sortBy == rhs.sortBy && lhs.ascending == rhs.ascending
    }
}

@Observable
public class IncomeDivisionSearchVM {
    public init() {
        
    }
    
    public var criteria: IncomeDividerSearchCriteria = .init();
    private var _cache: [IncomeDivision] = []
    
    public func update(_ data: [IncomeDivision]) {
        let queryStr = self.criteria.query.trimmingCharacters(in: .whitespaces).lowercased()
        var filtered: [IncomeDivision];
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
    
    public var cache: [IncomeDivision] {
        _cache
    }
}



struct AllIncomeDivisionsSearch : View {
    init(result: Binding<IncomeDivision?>) {
        self._result = result
        self._selection = .init(initialValue: result.wrappedValue?.id)
    }
    
    @Binding var result: IncomeDivision?;
    @State private var selection: IncomeDivision.ID?;
    
    @Query private var budgets: [IncomeDivision];
    @Bindable private var inspect: InspectionManifest<IncomeDivision> = .init();
    @Bindable private var query: IncomeDivisionSearchVM = .init()
    @State private var showPopover = false;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private func contextMenuSel(_ selection: Set<IncomeDivision.ID>) -> some View {
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
        Table(query.cache, selection: $selection) {
            TableColumn("Name") { budget in
                if horizontalSizeClass == .compact {
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
                }
                else {
                    Text(budget.name)
                }
            }
            
            if !query.criteria.hideFinalized {
                TableColumn("Finalized") { (budget: IncomeDivision) in
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
            .contextMenu(forSelectionType: IncomeDivision.ID.self, menu: contextMenuSel)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Income Division Search")
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
                                    ForEach(IncomeDividerSortField.allCases, id: \.id) { field in
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
            
            fullSized
            
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
            .onChange(of: selection) { _, newValue in
                guard let id = newValue, let target = query.cache.first(where: { $0.id == id } ) else {
                    result = nil
                    return;
                }
                
                result = target;
            }
            .sheet(item: $inspect.value) { item in
                IncomeDivisionCloseInspect(data: item)
            }
    }
}

#Preview {
    
    DebugContainerView {
        AllIncomeDivisionsSearch(result: .constant(nil))
    }
}
