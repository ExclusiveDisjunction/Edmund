//
//  ElementIEContext.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/6/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct SubmitActionData {
    public typealias Callback = @MainActor (ModelContext, UndoManager?, UniqueEngine) async -> Bool;
    
    @MainActor
    public init(_ callback: @escaping Self.Callback, context: ModelContext, undoManager: UndoManager?, unique: UniqueEngine) {
        self.callback = callback
        self.context = context
        self.undo = undoManager
        self.unique = unique
    }
    
    public let callback: Self.Callback;
    public var context: ModelContext?;
    public var undo: UndoManager?
    public var unique: UniqueEngine;
    
    @MainActor
    public func callAsFunction() async -> Bool {
        if let context = context {
            return await callback(context, undo, unique)
        }
        else {
            return false
        }
    }
}

public struct SubmitAction {
    public init() {
        self.data = nil;
    }
    @MainActor
    public init(_ data: SubmitActionData) {
        self.data = data
    }
    
    public var data: SubmitActionData?
    
    @MainActor
    public func callAsFunction() async -> Bool {
        if let data = data {
            return await data()
        }
        else {
            return false
        }
    }
}

public struct SubmitActionKey : EnvironmentKey {
    public typealias Value = SubmitAction
    
    public static var defaultValue: SubmitAction {
        .init()
    }
}
public struct ElementIsEditKey: EnvironmentKey {
    public typealias Value = Bool
    public static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    @MainActor
    var elementSubmit: SubmitAction {
        get {
            self[SubmitActionKey.self]
        }
        set {
            self[SubmitActionKey.self] = newValue
        }
    }
    
    var elementIsEdit: Bool {
        get { self[ElementIsEditKey.self] }
        set { self[ElementIsEditKey.self] = newValue }
    }
}


