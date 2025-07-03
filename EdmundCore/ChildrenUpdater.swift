//
//  ChildUpdateRecord.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Foundation
import SwiftData

@MainActor
public func mergeAndUpdateChildren<T>(list: inout [T], merging: [T.Snapshot], context: ModelContext?, unique: UniqueEngine) async throws(UniqueFailureError<T.ID>) where T: SnapshotableElement, T: DefaultableElement, T: Identifiable, T.ID == T.Snapshot.ID, T: PersistentModel {
    let old: [T.ID : Record] = .init(uniqueKeysWithValues: list.map { ($0.id, .init($0)) } )
    var new: [T] = []
    
    for item in merging {
        if let record = old[item.id] {
            try await record.data.update(item, unique: unique)
            record.visisted = true
            new.append(record.data)
        }
        else {
            let temp = T()
            try await temp.update(item, unique: unique)
            await MainActor.run {
                context?.insert(temp)
            }
            new.append(temp)
        }
    }
    
    let toDelete = old.values.filter { !$0.visisted }
    if let context = context {
        await MainActor.run {
            for item in toDelete {
                context.delete(item.data)
            }
        }
    }
    
    do {
        try await MainActor.run {
            list = new;
            try context?.save()
        }
    }
    catch let e {
        print("unable to save model context, reason \(e.localizedDescription)")
    }
}

fileprivate class Record<T> where T: SnapshotableElement, T: DefaultableElement, T: Identifiable, T.ID == T.Snapshot.ID, T: PersistentModel {
    fileprivate init(_ data: T) {
        self.data = data
        self.visisted = false
    }
    
    fileprivate var data: T;
    fileprivate var visisted: Bool;
}
