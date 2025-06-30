//
//  Query.swift
//  Edmund
//
//  Created by Hollan on 4/22/25.
//

import SwiftUI

/// Represents a data type that can be used for sorting options.
public protocol Sortable: CaseIterable, Identifiable, Hashable, Equatable where Self.ID == Self {
    /// The data type that the sorting will take place on.
    associatedtype On
    
    /// A localized description of the sort.
    var toString: LocalizedStringKey { get }
    /// A question asking about the order. For example, 'Alphabetical' would be used for a name based sort.
    var ascendingQuestion: LocalizedStringKey { get }
    
    /// Performs the actual sorting.
    func compare(_ lhs: On, _ rhs: On, _ ascending: Bool) -> Bool;
}
/// Represents a data type that can be used for filtering options.
public protocol Filterable: CaseIterable, Identifiable, Hashable, Equatable where Self.ID == Self {
    /// The data type that the filtering will take place on.
    associatedtype On
    
    /// The name of the filter.
    var name: LocalizedStringKey { get }
    /// The plural name of the filter.
    var pluralName: LocalizedStringKey { get }
    
    /// Determiens if the value passed is accepted by the filter.
    func accepts(_ val: On) -> Bool;
}

/// Represents a data type that supports querying, using the `QueryManifest` object.
public protocol Queryable {
    /// The type used for sorting
    associatedtype SortType: Sortable where SortType.On == Self
    /// The type used for filtering
    associatedtype FilterType: Filterable where FilterType.On == Self
    
    
}
