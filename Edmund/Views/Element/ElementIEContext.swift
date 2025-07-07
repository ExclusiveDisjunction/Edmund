//
//  ElementIEContext.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/6/25.
//

import SwiftUI

public struct SubmitAction {
    public init(_ data: (() async -> Bool)?) {
        self.data = data
    }
    
    private var data: (() async -> Bool)?;
    
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
        .init(nil)
    }
}
public struct ElementIsEditKey: EnvironmentKey {
    public typealias Value = Bool
    public static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    var elementSubmit: SubmitAction {
        get { self[SubmitActionKey.self] }
        set { self[SubmitActionKey.self] = newValue }
    }
    
    var elementIsEdit: Bool {
        get { self[ElementIsEditKey.self] }
        set { self[ElementIsEditKey.self] = newValue }
    }
}


