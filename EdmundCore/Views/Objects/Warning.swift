//
//  Warning.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI

/// A simple basis for what warnings should include.
public protocol WarningBasis : Identifiable {
    /// The encoded message that the warning presents.
    var message: LocalizedStringKey { get }
}

/// The warning message to be presented.
public enum SelectionWarningKind: Int, Identifiable, WarningBasis {
    
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

/// A string-based message used to indicate errors for the UI.
public struct StringWarning: Identifiable, WarningBasis {
    public init(_ message: LocalizedStringKey, id: UUID = UUID()) {
        self.message = message
        self.id = id
    }
    public let message: LocalizedStringKey
    
    public var id: UUID ;
}

public struct ValidationWarning : Identifiable, WarningBasis {
    public init(_ warnings: [ValidationFailure], id: UUID = UUID()) {
        self.warnings = warnings;
        self.id = id
    }
    
    public let warnings: [ValidationFailure];
    public var id: UUID;
    
    public var message: LocalizedStringKey {
        "There are one or more errors with the data inputted."
    }
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

@Observable
public class ValidationWarningManifest: BaseWarningManifest<ValidationWarning> {
    @ViewBuilder
    public var content: some View {
        if let warning = self.warning {
            VStack {
                Text("The following errors are present:")
                ForEach(warning.warnings, id: \.id) { warning in
                    warning.display
                }
            }
        }
        else {
            Text("No warnings to report")
        }
    }
}

/// A specalized version of `BaseWarningManifest<T>` that works for `WarningKind` values.
public typealias SelectionWarningManifest = BaseWarningManifest<SelectionWarningKind>;
/// A specalized version of `BaseWarningManifest<T>` that works for `WarningMessage` values.
public typealias StringWarningManifest = BaseWarningManifest<StringWarning>
