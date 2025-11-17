//
//  ChildUpdateRecord.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Foundation
import SwiftData

/// A structure over a old list, a new list of snapshots, with different strategies to update the source list.
/// Use this structure with persistent model classes to update the source list with snapshots.
///
@MainActor
public struct ChildUpdater<T, S> where T: PersistentModel {
    /// A helper class used to determine updates with the merge-by-id strategy.
    fileprivate class Record {
        fileprivate init(_ data: T) {
            self.data = data
            self.visisted = false
        }
        
        /// The associated data
        fileprivate var data: T;
        /// True if the ID of `data` was found in the snapshots.
        fileprivate var visisted: Bool;
    }
    
    /// Constructs a `ChildUpdater` using the specified data.
    /// - Parameters:
    ///     - source: The list that contains instances to be updated.
    ///     - snapshots: The lists of `T.Snapshot`s that can be used to update `source` instances with.
    ///     - context: An optional model context that is used to insert & delete elements.
    ///     - unique: The unique engine attached to the instances to ensure unique elements.
    public init(source: [T], snapshots: [S], context: ModelContext? = nil, unique: UniqueEngine) {
        self.source = source
        self.incoming = snapshots
        self.context = context
        self.unique = unique
    }
    
    /// The source list of elements
    private let source: [T];
    /// The incoming snapshots to update `source` with.
    private let incoming: [S]
    /// An optional model context attached for updating, inserting, and deleting.
    private let context: ModelContext?;
    /// The unique engine associated with the instances.
    private let unique: UniqueEngine;
}
extension ChildUpdater {
    public typealias UpdateClosure = @MainActor (T, S, UniqueEngine) async throws(UniqueFailureError) -> Void;
    public typealias ConstructClosure = @MainActor (S, UniqueEngine) async throws(UniqueFailureError) -> T;
    
    /// Updates the `oldList` elements to the snapshot values provided by `newList`.
    /// - Throws: `UniqueFailureError<T.ID>` by the call to `T.update(_:unique:)`.
    @MainActor
    private func joinLists<S1, S2>(oldList: S1, newList: S2, update: UpdateClosure) async throws(UniqueFailureError) where S1: Sequence, S2: Sequence, S1.Element == T, S2.Element == S {
        for (old, new) in zip(oldList, newList) {
            try await update(old, new, unique)
        }
    }
    
    /// Joins the lists by comparing length.
    /// If the lists are the same size, it will just update the source with the incoming.
    /// If the source list is smaller, the existing elements will be updated, and new elements will be inserted.
    /// If the source list is larger, then the matching elements will be updated, while the rest will be purged.
    /// - Note: This function does not call `ModelContext.save()`.
    /// - Returns: The updated list to store in the parent type.
    /// - Throws: `UniqueFailureError<T.ID>` based on the `.update(_:unique:)` method of `T`. If that method does not throw, this will never throw.
    @MainActor
    public consuming func joinByLength(update: UpdateClosure, create: ConstructClosure) async throws(UniqueFailureError) -> [T] {
        if source.count == incoming.count {
            try await self.joinLists(oldList: source, newList: incoming, update: update)
            return source
        }
        else if incoming.count > source.count {
            let matched = incoming[0..<source.count];
            try await self.joinLists(oldList: source, newList: matched, update: update)
            
            var newInstances: [T] = [];
            let joiningPoints = incoming[source.count...];
            newInstances.reserveCapacity(joiningPoints.count)
            for point in joiningPoints {
                let new = try await create(point, unique)
                newInstances.append(new)
                context?.insert(new)
            }
            
            let allPoints = source + newInstances;
            return allPoints
        }
        else {
            let keeping = Array(source[..<incoming.count]);
            let deleting = source[incoming.count...];
            
            try await self.joinLists(oldList: keeping, newList: incoming, update: update);
            if let context = context {
                for item in deleting {
                    context.delete(item)
                }
            }
            
            return keeping;
        }
    }
}
extension ChildUpdater where T: Identifiable, S: Identifiable, T.ID == S.ID {
    @MainActor
    public consuming func mergeById(update: Self.UpdateClosure, construct: Self.ConstructClosure) async throws(UniqueFailureError) -> [T] {
        let old: [T.ID : Record] = .init(uniqueKeysWithValues: source.map { ($0.id, .init($0)) } )
        var new: [T] = []
        
        for item in incoming {
            if let record = old[item.id] {
                try await update(record.data, item, unique)
                record.visisted = true
                new.append(record.data)
            }
            else {
                let temp = try await construct(item, unique)
                await MainActor.run {
                    context?.insert(temp)
                }
                new.append(temp)
            }
        }
        
        let toDelete = old.values.filter { !$0.visisted }
        if let context = context {
            for item in toDelete {
                context.delete(item.data)
            }
        }
        
        return new;
    }
}

extension ChildUpdater where T: SnapshotableElement, T.Snapshot == S {
    /// Updates the `oldList` elements to the snapshot values provided by `newList`.
    /// - Throws: `UniqueFailureError<T.ID>` by the call to `T.update(_:unique:)`.
    @MainActor
    private func joinLists<S1, S2>(oldList: S1, newList: S2) async throws(UniqueFailureError) where S1: Sequence, S2: Sequence, S1.Element == T, S2.Element == S {
        for (old, new) in zip(oldList, newList) {
            try await old.update(new, unique: unique)
        }
    }
}
extension ChildUpdater where T: SnapshotConstructableElement, T: Identifiable, T.Snapshot == S {
    /// Joins the lists by comparing length.
    /// If the lists are the same size, it will just update the source with the incoming.
    /// If the source list is smaller, the existing elements will be updated, and new elements will be inserted.
    /// If the source list is larger, then the matching elements will be updated, while the rest will be purged.
    /// - Note: This function does not call `ModelContext.save()`.
    /// - Returns: The updated list to store in the parent type.
    /// - Throws: `UniqueFailureError<T.ID>` based on the `.update(_:unique:)` method of `T`. If that method does not throw, this will never throw.
    @MainActor
    public consuming func joinByLength() async throws(UniqueFailureError) -> [T] {
        if source.count == incoming.count {
            try await self.joinLists(oldList: source, newList: incoming)
            return source
        }
        else if incoming.count > source.count {
            let matched = incoming[0..<source.count];
            try await self.joinLists(oldList: source, newList: matched)
            
            var newInstances: [T] = [];
            let joiningPoints = incoming[source.count...];
            newInstances.reserveCapacity(joiningPoints.count)
            for point in joiningPoints {
                let new = try await T(snapshot: point, unique: unique)
                newInstances.append(new)
                context?.insert(new)
            }
            
            let allPoints = source + newInstances;
            return allPoints
        }
        else {
            let keeping = Array(source[..<incoming.count]);
            let deleting = source[incoming.count...];
            
            try await self.joinLists(oldList: keeping, newList: incoming);
            if let context = context {
                for item in deleting {
                    context.delete(item)
                }
            }
            
            return keeping;
        }
    }
}
extension ChildUpdater where T: SnapshotConstructableElement & Identifiable, T.Snapshot == S, S: Identifiable, S.ID == T.ID {
    /// Joins the list by updating elements based on IDs.
    /// Use this approach when IDs matter.
    /// This will take all elements by ID, and if any snapshot matches an ID, it will update them. Any new snapshots will be created and appended, while any values not matched to a snapshot ID will be removed.
    /// - Note: This function does not call `ModelContext.save()`.
    /// - Returns: The updated list to store in the parent type.
    /// - Throws: `UniqueFailureError<T.ID>` based on the `.update(_:unique:)` method of `T`. If that method does not throw, this will never throw.
    @MainActor
    public consuming func mergeById() async throws(UniqueFailureError) -> [T]{
        let old: [T.ID : Record] = .init(uniqueKeysWithValues: source.map { ($0.id, .init($0)) } )
        var new: [T] = []
        
        for item in incoming {
            if let record = old[item.id] {
                try await record.data.update(item, unique: unique)
                record.visisted = true
                new.append(record.data)
            }
            else {
                let temp = try await T(snapshot: item, unique: unique)
                await MainActor.run {
                    context?.insert(temp)
                }
                new.append(temp)
            }
        }
        
        let toDelete = old.values.filter { !$0.visisted }
        if let context = context {
            for item in toDelete {
                context.delete(item.data)
            }
        }
        
        return new;
    }
}
