//
//  UndoWrappers.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/6/25.
//

import Foundation
import SwiftData
import EdmundCore

protocol UndoManagerWrapper : AnyObject, Sendable {
    @MainActor
    func update() async;
}
extension UndoManagerWrapper {
    @MainActor
    func registerWith(manager: UndoManager?) {
        manager?.registerUndo(withTarget: self, handler: { item in
            Task { @MainActor in
                await item.update()
            }
        })
    }
}

/// A class that can be used to re-insert a bit of data from a snapshot
class UndoDeleteWrapper<T> : UndoManagerWrapper, @unchecked Sendable where T: SnapshotableElement, T: IsolatedDefaultableElement, T.ID: Sendable {
    init(data: T.Snapshot, unique: UniqueEngine, context: ModelContext) {
        self.data = data
        self.unique = unique
        self.context = context
    }
    
    let data: T.Snapshot;
    let unique: UniqueEngine;
    weak var context: ModelContext?;
    
    @MainActor
    public func update() async {
        if let context = context {
            let new = T()
            context.insert(new)
            let _ = try? await new.update(data, unique: unique)
        }
    }
}
class UndoAddWrapper<T> : UndoManagerWrapper, @unchecked Sendable where T: PersistentModel, T.ID: Sendable {
    init(element: T) {
        self.element = element
    }
    
    weak var element: T?;
    
    @MainActor
    public func update() {
        if let element = element {
            if element.isDeleted { return }
            
            if let context = element.modelContext {
                context.delete(element)
            }
        }
    }
}
class UndoAddUniqueWrapper<T> : UndoManagerWrapper, @unchecked Sendable where T: PersistentModel, T.ID: Sendable {
    convenience init(element: T, unique: UniqueEngine) where T: UniqueElement {
        self.init(id: T.objId, element: element, unique: unique)
    }
    init(id: ObjectIdentifier, element: T, unique: UniqueEngine) {
        self.id = id
        self.element = element
        self.unique = unique
    }
    
    let id: ObjectIdentifier;
    weak var element: T?;
    let unique: UniqueEngine;
    
    @MainActor
    public func update() async {
        if let element = element {
            if element.isDeleted { return }
            
            if let context = element.modelContext {
                context.delete(element)
            }
            
            await unique.releaseId(key: id, id: element.id)
        }
    }
}

class UndoSnapshotApplyWrapper<T> : UndoManagerWrapper, @unchecked Sendable where T: SnapshotableElement, T.ID: Sendable {
    init(item: T, snapshot: T.Snapshot, engine: UniqueEngine) {
        self.item = item
        self.snapshot = snapshot
        self.engine = engine
    }
    
    weak var item: T?;
    let engine: UniqueEngine;
    let snapshot: T.Snapshot;
    
    @MainActor
    public func update() async {
        if let item = item {
            guard !item.isDeleted else { return }
            
            let _ = try? await item.update(snapshot, unique: engine)
        }
    }
}
