//
//  Queryable.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/31/25.
//

import SwiftUI
import SwiftData

protocol Sortable: CaseIterable, Identifiable, Hashable, Equatable where Self.ID == Self {
    associatedtype On
    
    var toString: String { get }
    var ascendingQuestion: String { get }
    
    func compare(_ lhs: On, _ rhs: On, _ ascending: Bool) -> Bool;
}
protocol Filterable: CaseIterable, Identifiable, Hashable, Equatable where Self.ID == Self {
    associatedtype On
    
    var toString: String { get }
    var toStringPlural: String { get }
    
    func accepts(_ val: On) -> Bool;
}

protocol Queryable {
    associatedtype SortType: Sortable where SortType.On == Self
    associatedtype FilterType: Filterable where FilterType.On == Self

}

@Observable
class QueryFilter<T>: Identifiable where T: Queryable {
    init(_ filter: T.FilterType) {
        self.id = UUID();
        self.filter = filter
        self.isIncluded = true
    }
    
    var id: UUID;
    var filter: T.FilterType;
    var isIncluded: Bool;
    
    func accepts(_ item: T) -> Bool {
        isIncluded && filter.accepts(item)
    }
}

@Observable
class QueryProvider<T> where T: Queryable {
    init(_ sorting: T.SortType) {
        self.sorting = sorting
        self.ascending = true
        self.filter = T.FilterType.allCases.map { QueryFilter($0) }
    }
    
    var sorting: T.SortType
    var ascending: Bool;
    var filter: [QueryFilter<T>];
    
    func apply(_ on: [T]) -> [T] {
        let filtered = on.filter { item in
            filter.first(where: {$0.accepts(item) } ) != nil
        }
        
        return filtered.sorted { lhs, rhs in
            sorting.compare(lhs, rhs, ascending)
        }
    }
}

struct QueryHandle<T>: Identifiable where T: Queryable {
    @Bindable var provider: QueryProvider<T>
    var id = UUID();
}

struct QueryButton<T>: View where T: Queryable, T.SortType.AllCases: RandomAccessCollection, T.FilterType.AllCases: RandomAccessCollection {
    @Bindable var provider: QueryProvider<T>;
    @State private var handle: QueryHandle<T>?;
    
    var body: some View {
        Button(action: {
            handle = .init(provider: provider)
        }) {
            Label("Sort & Filter", systemImage: "line.3.horizontal.decrease.circle")
        }.popover(item: $handle) { item in
            QueryPopout(provider: item.provider)
        }
    }
}

struct QueryPopout<T> : View where T: Queryable, T.SortType.AllCases: RandomAccessCollection, T.FilterType.AllCases: RandomAccessCollection {
    @Bindable var provider: QueryProvider<T>;
    
    var body: some View {
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
                    Toggle(filter.filter.toStringPlural, isOn: $filter.isIncluded)
                }
            }
        }.padding()
        #if os(iOS)
            .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}

#Preview {
    let provider = QueryProvider<Bill>(.name);
    QueryPopout(provider: provider).modelContainer(Containers.previewContainer)
}
