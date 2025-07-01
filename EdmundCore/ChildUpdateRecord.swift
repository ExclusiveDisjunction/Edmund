//
//  ChildUpdateRecord.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import Foundation
import SwiftData

class ChildUpdateRecord<T> where T: Identifiable, T: SnapshotableElement, T.ID == T.Snapshot.ID {
    public init(_ data: T) {
        self.data = data
        self.visisted = false
    }
    
    public var data: T;
    public var visisted: Bool;
    
    @MainActor
    public static func updateOrInsert(_ snap: T.Snapshot, old: Dictionary<T.ID, ChildUpdateRecord<T>>, modelContext: ModelContext?, unique: UniqueEngine, list: inout [T]) throws(UniqueFailureError<T.ID>) where T: PersistentModel, T: DefaultableElement {
        let new: T;
        if let target = old[snap.id] {
            try target.data.update(snap, unique: unique)
            target.visisted = true
            new = target.data
        }
        else {
            new = T()
            try new.update(snap, unique: unique)
            modelContext?.insert(new)
        }
        
        list.append(new)
    }
}
