//
//  Warning.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

public protocol WarningBasis : Identifiable {
    var message: LocalizedStringKey { get }
}

/// The warning message to be presented.
public enum WarningKind: Int, Identifiable, WarningBasis {
    
    /// The warning that no elements are selected, when at least one was expected.
    case noneSelected = 0
    /// The warning that too many elements are selected, as only one was expected.
    case tooMany = 1
    
    public var id: Self { self }
    /// Returns the `LocalizedStringKey` that
    public var message: LocalizedStringKey {
        switch self {
            case .noneSelected: "noItems"
            case .tooMany: "tooManyItems"
        }
    }
}

public struct WarningMessage: Identifiable, WarningBasis {
    public init(message: LocalizedStringKey) {
        self.message = message
    }
    public let message: LocalizedStringKey
    
    public var id: UUID { UUID() }
}

/// An observable class that provides warning funcntionality. It includes a memeber, `isPresented`, which can be bound. This value will become `true` when the internal `warning` is not `nil`.
@Observable
public class BaseWarningManifest<T> where T: WarningBasis {
    public init() {
        warning = nil;
    }
    
    public var warning: T?;
    public var message: LocalizedStringKey? { warning?.message }
    public var isPresented: Bool {
        get { warning != nil }
        set {
            if self.isPresented == newValue { return }
            
            warning = nil
        }
    }
}

public typealias WarningManifest = BaseWarningManifest<WarningKind>;
public typealias StringWarningManifest = BaseWarningManifest<WarningMessage>
