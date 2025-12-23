//
//  EditManifests.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/23/25.
//

import CoreData

public protocol EditableElementManifest : ~Copyable {
    associatedtype Target: NSManagedObject;
    
    var target: Target { get }
    mutating func save() throws;
    mutating func reset() throws;
}

@MainActor
public struct ElementEditManifest<T> : ~Copyable, EditableElementManifest where T: NSManagedObject {
    public init(using: NSPersistentContainer, from: T) {
        self.cx = using.newBackgroundContext();
        self.target = cx.object(with: from.objectID) as! T;
        self.hash = self.target.hashValue;
    }
    public init?(using: NSPersistentContainer, fromId: NSManagedObjectID) {
        self.cx = using.newBackgroundContext();
        
        guard let target = cx.object(with: fromId) as? T else {
            return nil;
        }
        
        self.target = target;
        self.hash = self.target.hashValue;
    }
    
    private var hash: Int;
    private var didSave: Bool = false;
    private let cx: NSManagedObjectContext;
    public let target: T;
    
    public var hasChanges: Bool {
        !self.didSave || self.target.hashValue != hash
    }
    
    public mutating func save() throws {
        try cx.save()
        didSave = true;
        hash = target.hashValue;
    }
    public mutating func reset() {
        cx.rollback()
        self.didSave = false;
        self.hash = target.hashValue;
    }
}

@MainActor
public struct ElementAddManifest<T> : ~Copyable, EditableElementManifest where T: NSManagedObject {
    public init(using: NSPersistentContainer, filling: @MainActor (T) throws -> Void) rethrows {
        self.cx = using.newBackgroundContext();
        
        let target = T(context: self.cx);
        try filling(target);
        
        self.target = target;
        self.hash = target.hashValue;
        
        self.cx.insert(self.target);
    }
    
    private var hash: Int;
    private var didSave: Bool = false;
    private let cx: NSManagedObjectContext;
    public let target: T;
    
    public var hasChanges: Bool {
        !self.didSave || self.target.hashValue != hash
    }
    
    public mutating func save() throws {
        try cx.save()
        didSave = true;
        hash = target.hashValue;
    }
    public mutating func reset() {
        cx.rollback()
        self.didSave = false;
        self.hash = target.hashValue;
    }
}

@MainActor
public enum ElementSelectionMode<T> : ~Copyable where T: NSManagedObject {
    case edit(ElementEditManifest<T>)
    case add(ElementAddManifest<T>)
    case inspect(T)
    
    public static func newEdit(using: NSPersistentContainer, from: T) -> ElementSelectionMode<T> {
        return .edit(ElementEditManifest(using: using, from: from))
    }
    public static func newEdit(using: NSPersistentContainer, from: NSManagedObjectID) -> ElementSelectionMode<T>? {
        guard let manifest = ElementEditManifest<T>(using: using, fromId: from) else {
            return nil;
        }
        return .edit(manifest)
    }
    public static func newAdd(using: NSPersistentContainer, filling: @MainActor (T) throws -> Void) rethrows -> ElementSelectionMode<T> {
        return .add( try ElementAddManifest(using: using, filling: filling) )
    }
    public static func newInspect(val: T) -> ElementSelectionMode<T> {
        return .inspect(val)
    }
}
