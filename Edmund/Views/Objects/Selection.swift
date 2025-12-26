//
//  Selection.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/25/25.
//

import SwiftUI

/// A protocol for some type that wraps the logic for selection based filtering of data.
public protocol SelectionContextProtocol {
    associatedtype Element: Identifiable;
    
    var selectedItems: [Element] { get }
}

/// A selection that has an active, shared binding to what is currently selected.
public struct SelectionContext<C> : SelectionContextProtocol where C: RandomAccessCollection, C.Element: Identifiable {
    public let data: C;
    public let selection: Binding<Set<C.Element.ID>>;
    
    public var selectedItems: [C.Element] {
        data.filter { selection.wrappedValue.contains($0.id) }
    }
    
    /// Unwraps the inner binding to keep a static selection.
    public func freeze() -> FrozenSelectionContext<C> {
        FrozenSelectionContext(data: self.data, selection: self.selection.wrappedValue)
    }
}
/// A selection that has a frozen storage of what is currently selected.
public struct FrozenSelectionContext<C> : SelectionContextProtocol where C: RandomAccessCollection, C.Element: Identifiable {
    public let data: C;
    public let selection: Set<C.Element.ID>;
    
    public var selectedItems: [C.Element] {
        data.filter { selection.contains($0.id) }
    }
}

/// A context for selection based on a Core Data query.
@MainActor
@propertyWrapper
public struct QuerySelection<T> : DynamicProperty where T: NSManagedObject & Identifiable {
    public init(sortDescriptors: [SortDescriptor<T>] = [], predicate: NSPredicate? = nil, animation: Animation? = nil) {
        self._data = .init(sortDescriptors: sortDescriptors, predicate: predicate, animation: animation)
    }
    
    @FetchRequest private var data: FetchedResults<T>;
    @State private var selection: Set<T.ID> = .init();
    
    public func configure(sortDescriptors: [SortDescriptor<T>] = [], predicate: NSPredicate? = nil) {
        self._data.projectedValue.nsPredicate.wrappedValue = predicate;
        self._data.projectedValue.nsSortDescriptors.wrappedValue = sortDescriptors.compactMap { NSSortDescriptor($0) };
    }
    
    public var wrappedValue: SelectionContext<FetchedResults<T>> {
        SelectionContext(
            data: self.data,
            selection: $selection
        )
    }
    
}
/// A context for selection based on a Core Data query that allows for post-query filtering.
/// This allows for more advanced queries, but comes at an overhead cost.
@MainActor
@propertyWrapper
public struct FilterableQuerySelection<T> : DynamicProperty where T: NSManagedObject & Identifiable {
    public init(sortDescriptors: [SortDescriptor<T>] = [], predicate: NSPredicate? = nil, animation: Animation? = nil, filtering: @MainActor @escaping (T) -> Bool) {
        self._data = .init(sortDescriptors: sortDescriptors, predicate: predicate, animation: animation)
        self.filtering = filtering
    }
    
    @FetchRequest private var data: FetchedResults<T>;
    @State private var selection: Set<T.ID> = .init();
    private let filtering: @MainActor (T) -> Bool;
    
    public func configure(sortDescriptors: [SortDescriptor<T>]? = nil, predicate: NSPredicate? = nil) {
        if let predicate = predicate {
            self._data.projectedValue.nsPredicate.wrappedValue = predicate;
        }
        
        if let sortDescriptors = sortDescriptors {
            self._data.projectedValue.nsSortDescriptors.wrappedValue = sortDescriptors.compactMap { NSSortDescriptor($0) };
        }
    }
    public func noPredicate() {
        self._data.projectedValue.nsPredicate.wrappedValue = nil;
    }
    
    public var wrappedValue: SelectionContext<[T]> {
        SelectionContext(
            data: self.data.filter(filtering),
            selection: $selection
        )
    }
}

/// A context for selection based on a provided collection of data.
@propertyWrapper
public struct SourcedSelection<C> : DynamicProperty where C: RandomAccessCollection, C.Element: Identifiable {
    public init(data: C) {
        self.data = data
    }
    
    public var data: C;
    @State private var selection: Set<C.Element.ID> = .init();
    
    public var wrappedValue: SelectionContext<C> {
        SelectionContext(
            data: data,
            selection: $selection
        )
    }
}

public extension Table {
    /// Constructs the table around a selection context, binding the selection set and providing the data for the table.
    init<C>(
        context: SelectionContext<C>,
        @TableColumnBuilder<Value, Never> columns: () -> Columns
    ) where
        C: RandomAccessCollection,
        C.Element: Identifiable,
        C.Element == Value,
        Rows == TableForEachContent<C>
    {
        self.init(context.data, selection: context.selection, columns: columns)
    }
    
    /// Constructs the table around a selection context, binding the selection set and providing the data for the table.
    init<C, Sort>(
        context: SelectionContext<C>,
        sortOrder: Binding<[Sort]>,
        @TableColumnBuilder<Value, Never> columns: () -> Columns
    ) where
        C: RandomAccessCollection,
        C.Element: Identifiable,
        C.Element == Value,
        Rows == TableForEachContent<C>,
        Sort: SortComparator,
        C.Element == Sort.Compared
    {
        self.init(context.data, selection: context.selection, sortOrder: sortOrder, columns: columns)
    }
}
public extension List {
    /// Constructs the list around a selection context, binding the selection set and providing the data for the list.
    init<C, RowContent>(
        context: SelectionContext<C>,
        @ViewBuilder rowContent: @escaping (C.Element) -> RowContent
    ) where
        C: RandomAccessCollection,
        C.Element: Identifiable,
        Content == ForEach<C, C.Element.ID, RowContent>,
        SelectionValue == Set<C.Element.ID>
    {
        self.init(context.data, id: \C.Element.id, selection: context.selection, rowContent: rowContent)
    }
}
