//
//  UndoTests.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/9/25.
//

import Testing
import SwiftUI
import SwiftData
import EdmundCore
import Edmund

struct UndoTests {
    @MainActor
    func writeAddWrapper<T>(data: T, undoManager: UndoManager, unique: UniqueEngine) where T: SnapshotableElement {
        if let uniqueElement = data as? any UniqueElement {
            let id = uniqueElement.getObjectId()
            let wrapper = UndoAddUniqueWrapper(id: id, element: data, unique: unique)
            wrapper.registerWith(manager: undoManager)
        }
        else {
            let wrapper = UndoAddWrapper(element: data)
            wrapper.registerWith(manager: undoManager)
        }
        
        undoManager.setActionName("add")
    }
    @MainActor
    func writeApplyWrapper<T>(data: T, undoManager: UndoManager, unique: UniqueEngine) where T: SnapshotableElement {
        let previous = data.makeSnapshot()
        let wrapper = UndoSnapshotApplyWrapper(item: data, snapshot: previous, engine: unique)
        wrapper.registerWith(manager: undoManager)
        
        undoManager.setActionName("update")
    }
    
    @MainActor
    @Test
    func testAdder() async throws {
        let undo: UndoManager = .init();
        let container = try Containers.debugContainer()
    
        let context = try UniqueContext(container.context)
        let unique = UniqueEngine();
        await unique.fill(context)
        
        let new = Account("Testing Account", kind: .checking, creditLimit: nil, interest: 0.1, location: nil, children: [])
        writeAddWrapper(data: new, undoManager: undo, unique: unique)
        
        container.context.insert(new)
        
        #expect(undo.canUndo)
        
        /*
        if undo.canUndo {
            undo.undo()
            
            #expect(new.isDeleted)
        }
         */
    }
    
    @MainActor
    @Test
    func testEdit() async throws {
        let undo: UndoManager = .init();
        let container = try Containers.debugContainer()
        
        let context = try UniqueContext(container.context)
        let unique = UniqueEngine();
        await unique.fill(context)
        
        guard let object = try container.context.fetch(FetchDescriptor<Account>()).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        
        let oldName = object.name
        let snapshot = object.makeSnapshot()
        snapshot.hasInterest = true
        snapshot.interest = .init(rawValue: 1)
        
        writeApplyWrapper(data: object, undoManager: undo, unique: unique)
        try await object.update(snapshot, unique: unique)
        
        try container.context.save()
        
        #expect(undo.canUndo)
        
        /*
        if undo.canUndo {
            undo.undo()
            
            #expect(object.name == oldName)
        }
         */
    }
}
