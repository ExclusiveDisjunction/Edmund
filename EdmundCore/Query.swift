//
//  Query.swift
//  Edmund
//
//  Created by Hollan on 4/22/25.
//

import SwiftUI

/// Represents a data type that can be used for sorting options.
public protocol Sortable: CaseIterable, Identifiable, Hashable, Equatable where Self.ID == Self {
    
}
/// Represents a data type that can be used for filtering options.
public protocol Filterable: CaseIterable, Identifiable, Hashable, Equatable where Self.ID == Self {
    
}

/// Represents a data type that supports querying, using the `QueryManifest` object.
public protocol Queryable {
    /// The type used for sorting
    associatedtype SortType: Sortable
    /// The type used for filtering
    associatedtype FilterType: Filterable
    
    static func sort(_ data: [Self], using: SortType, order: SortOrder) -> [Self];
    static func filter(_ data: [Self], using: Set<FilterType>) -> [Self];
}
