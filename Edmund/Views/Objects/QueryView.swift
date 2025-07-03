//
//  Queryable.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/31/25.
//

import SwiftUI
import SwiftData
import EdmundCore

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
    
    /// Uses the sorting and filtering criteria to determine which objects from `on` should be inclued. The result is sotred in `cached`, so that the
    public func apply(_ on: [T]) {
        let filterSet: Set<T.FilterType> = .init(filter.filter { $0.isIncluded }.map { $0.filter })
        let filtered = T.filter(on, using: filterSet)
        
        let sortOrder: SortOrder = ascending ? .forward : .reverse
        
        cached = T.sort(filtered, using: self.sorting, order: sortOrder)
    }
}

/// A handle used by the `QueryButton` to provide popover functionality.
public struct QueryHandle<T>: Identifiable where T: Queryable {
    @Bindable public var provider: QueryManifest<T>
    public var id = UUID();
}

/// A UI element that uses a specific `QueryManifest<T>` to allow the user to change sorting & filtering criteria.
public struct QueryButton<T>: View where T: Queryable, T.SortType.AllCases: RandomAccessCollection, T.SortType: Displayable, T.FilterType.AllCases: RandomAccessCollection, T.FilterType: Displayable {
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
        }.sheet(item: $handle) { item in
            QueryPopout(provider: item.provider, isSheet: true)
        }
    }
}

/// The popout used by `QueryButton<T>`.
public struct QueryPopout<T> : View where T: Queryable, T.SortType.AllCases: RandomAccessCollection, T.SortType: Displayable, T.FilterType.AllCases: RandomAccessCollection, T.FilterType: Displayable {
    @Bindable public var provider: QueryManifest<T>;
    let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            Form {
                Section("Sort") {
                    Picker("Sort By", selection: $provider.sorting) {
                        ForEach(T.SortType.allCases, id: \.id) { sort in
                            Text(sort.display)
                                .tag(sort)
                        }
                    }
                    
                    Toggle("Ascending", isOn: $provider.ascending)
                }
                
                Section("Filter") {
                    ForEach($provider.filter) { $filter in
                        Toggle(filter.filter.display, isOn: $filter.isIncluded)
                    }
                }
            }
            
            Spacer()
            
            if isSheet {
                HStack {
                    Spacer()
                    Button("Ok", action: { dismiss() } )
                        .buttonStyle(.borderedProminent)
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
    QueryPopout(provider: provider, isSheet: false)
        .modelContainer(try! Containers.debugContainer())
}
