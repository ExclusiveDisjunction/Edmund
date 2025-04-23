//
//  Queryable.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/31/25.
//

import SwiftUI
import SwiftData

/// A specific filter for a query type. One is made per case of a `Filterable` type, and this stores if that filter is active or not.
@Observable
public class QueryFilter<T>: Identifiable, Equatable, Hashable where T: Queryable {
    init(_ filter: T.FilterType) {
        self.id = UUID();
        self.filter = filter
        self.isIncluded = true
    }
    
    public var id: UUID;
    /// The specific filter being held.
    public var filter: T.FilterType;
    /// When `true` this filter is not active, ie, the information is presented.
    public var isIncluded: Bool;

    public static func == (lhs: QueryFilter<T>, rhs: QueryFilter<T>) -> Bool {
        lhs.filter == rhs.filter && lhs.isIncluded == rhs.isIncluded
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(filter)
        hasher.combine(isIncluded)
    }
    
    /// Determines if the object should be included (not filtered out)
    public func accepts(_ item: T) -> Bool {
        isIncluded && filter.accepts(item)
    }
}

/// An observable class used to handle filtering & sorting.
/// This class can be tracked. This is on purpose. The design goal is to have this class, with an inital sorting. Whenever the sorting changes (use `.onChange`), you can call `.apply`. The user interface should use `.cached` to display the sorted and filtered data. This saves on expensive calls.
@Observable
public class QueryManifest<T> : Hashable, Equatable where T: Queryable {
    public init(_ sorting: T.SortType) {
        self.sorting = sorting
        self.ascending = true
        self.filter = T.FilterType.allCases.map { QueryFilter($0) }
        self.cached = []
    }
    
    /// Which sort is currently being used
    public var sorting: T.SortType
    /// If the sort is ascending
    public var ascending: Bool;
    /// All possible filters.
    public var filter: [QueryFilter<T>];
    /// The last result from `apply`.
    public var cached: [T];
    
    public static func == (lhs: QueryManifest<T>, rhs: QueryManifest<T>) -> Bool {
        lhs.sorting == rhs.sorting && lhs.ascending == rhs.ascending && lhs.filter == rhs.filter
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sorting)
        hasher.combine(ascending)
        hasher.combine(filter)
    }
    
    private func sortRank(lhs: T, rhs: T) -> Bool {
        sorting.compare(lhs, rhs, ascending)
    }
    
    /// Uses the sorting and filtering criteria to determine which objects from `on` should be inclued. The result is sotred in `cached`, so that the
    public func apply(_ on: [T]) {
        let filtered: [T] = on.filter { item in
            filter.first(where: { $0.accepts(item) } ) != nil
        }
        
        let sorted: [T] = filtered.sorted(by: sortRank)
        
        self.cached = sorted
    }
}

/// A handle used by the `QueryButton` to provide popover functionality.
public struct QueryHandle<T>: Identifiable where T: Queryable {
    @Bindable public var provider: QueryManifest<T>
    public var id = UUID();
}

/// A UI element that uses a specific `QueryManifest<T>` to allow the user to change sorting & filtering criteria.
public struct QueryButton<T>: View where T: Queryable, T.SortType.AllCases: RandomAccessCollection, T.FilterType.AllCases: RandomAccessCollection {
    public init(provider: QueryManifest<T>) {
        self.provider = provider;
        self.handle = nil;
    }
    
    @Bindable private var provider: QueryManifest<T>;
    @State private var handle: QueryHandle<T>?;
    
    public var body: some View {
        Button(action: {
            handle = .init(provider: provider)
        }) {
            Label("Sort & Filter", systemImage: "line.3.horizontal.decrease.circle")
        }.popover(item: $handle) { item in
            QueryPopout(provider: item.provider)
        }
    }
}

/// The popout used by `QueryButton<T>`.
public struct QueryPopout<T> : View where T: Queryable, T.SortType.AllCases: RandomAccessCollection, T.FilterType.AllCases: RandomAccessCollection {
    @Bindable public var provider: QueryManifest<T>;
    
    public var body: some View {
        Form {
            Section(header: Text("Sorting").font(.headline)) {
                Picker("Sort By", selection: $provider.sorting) {
                    ForEach(T.SortType.allCases, id: \.id) { sort in
                        Text(sort.toString).tag(sort)
                    }
                }
                
                Toggle(provider.sorting.ascendingQuestion, isOn: $provider.ascending)
            }
            
            Section(header: Text("Filters").font(.headline)) {
                ForEach($provider.filter) { $filter in
                    Toggle(filter.filter.pluralName, isOn: $filter.isIncluded)
                }
            }
        }.padding()
        #if os(iOS)
            .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}

#Preview {
    let provider = QueryManifest<BillBaseWrapper>(.name);
    QueryPopout(provider: provider).modelContainer(Containers.debugContainer)
}
