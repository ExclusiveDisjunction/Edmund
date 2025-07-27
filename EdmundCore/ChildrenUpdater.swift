//
//  ChildUpdateRecord.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Foundation
import SwiftData

public struct ChildUpdater<T> where T: SnapshotConstructableElement, T: Identifiable, T: PersistentModel, T.ID: Sendable {
    fileprivate class Record {
        fileprivate init(_ data: T) {
            self.data = data
            self.visisted = false
        }
        
        fileprivate var data: T;
        fileprivate var visisted: Bool;
    }
    
    private let source: [T];
    private let incoming: [T.Snapshot]
    private let context: ModelContext?;
    private let unique: UniqueEngine;
    
    @MainActor
    private func joinLists<S1, S2>(oldList: S1, newList: S2) async throws(UniqueFailureError<T.ID>) where S1: Sequence, S1.Element == T, S2: Sequence, S2.Element == T.Snapshot {
        for (old, new) in zip(oldList, newList) {
            try await old.update(new, unique: unique)
        }
    }
    
    @MainActor
    public consuming func flatJoin() async throws(UniqueFailureError<T.ID>) -> [T] {
        if source.count == incoming.count {
            
        }
    }
    
    @MainActor
    public consuming func mergeAndUpdate() async throws(UniqueFailureError<T.ID>) -> [T] where T.ID == T.Snapshot.ID {
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
