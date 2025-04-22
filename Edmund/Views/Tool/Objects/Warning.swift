//
//  Warning.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

protocol WarningBasis : Identifiable {
    var message: LocalizedStringKey { get }
}

/// The warning message to be presented.
enum WarningKind: Int, Identifiable, WarningBasis {
    
    /// The warning that no elements are selected, when at least one was expected.
    case noneSelected = 0
    /// The warning that too many elements are selected, as only one was expected.
    case tooMany = 1
    
    var id: Self { self }
    /// Returns the `LocalizedStringKey` that
    var message: LocalizedStringKey {
        switch self {
            case .noneSelected: "noItems"
            case .tooMany: "tooManyItems"
        }
    }
}

struct WarningMessage: Identifiable, WarningBasis {
    let message: LocalizedStringKey
    let title: LocalizedStringKey
    
    var id: UUID { UUID() }
}

/// An observable class that provides warning funcntionality. It includes a memeber, `isPresented`, which can be bound. This value will become `true` when the internal `warning` is not `nil`.
@Observable
class BaseWarningManifest<T> where T: WarningBasis {
    var warning: T?;
    var message: LocalizedStringKey? { warning?.message }
    var isPresented: Bool {
        get { warning != nil }
        set {
            if self.isPresented == newValue { return }
            
            warning = nil
        }
    }
}

typealias WarningManifest = BaseWarningManifest<WarningKind>;
typealias StringWarningManifest = BaseWarningManifest<WarningMessage>
