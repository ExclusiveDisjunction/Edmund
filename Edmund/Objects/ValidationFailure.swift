//
//  ValidationFailure.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI

/// A failure to validate a value out of a snapshot/element.
public enum ValidationFailure: Identifiable {
    /// A uniqueness check failed over a set of identifiers.
    case unique([ElementIdentifer])
    /// A field was empty
    case empty(LocalizedStringKey)
    /// A field was negative
    case negativeAmount(LocalizedStringKey)
    /// A field is too large
    case tooLargeAmount(LocalizedStringKey)
    /// A field is too small
    case tooSmallAmount(LocalizedStringKey)
    /// A field has invalid input
    case invalidInput(LocalizedStringKey)
    ///Happens when there is an internal expection that failed
    case internalError
    
    public var id: UUID { UUID() }
    
    /// A view that displays what went wrong with the validation failure.
    @ViewBuilder
    public var display: some View {
        switch self {
            case .unique(let elements):
                if let first = elements.first, elements.count == 1 {
                    HStack {
                        Text(first.name)
                        Text("must be unique", comment: "[property] must be unique")
                    }
                }
                else {
                    VStack {
                        Text("The following properties must be unique together:")
                        ForEach(elements, id: \.id) { element in
                            Text("\t")
                            Text(element.name)
                        }
                    }
                }
            case .empty(let key):
                HStack {
                    Text(key)
                    Text("is empty")
                }
            case .negativeAmount(let key):
                HStack {
                    Text(key)
                    Text("cannot be negative")
                }
            case .tooLargeAmount(let key):
                HStack {
                    Text(key)
                    Text("is too large")
                }
            case .tooSmallAmount(let key):
                HStack {
                    Text(key)
                    Text("is too small")
                }
            case .invalidInput(let key):
                HStack {
                    Text(key)
                    Text("is invalid")
                }
            case .internalError: Text("internalError")
        }
    }
}

/// An exception for `ValidationFailure` values.
public struct ValidationException : Error {
    public init(_ data: [ValidationFailure]) {
        self.data = data
    }
    
    /// The failures to present
    public let data: [ValidationFailure];
    
    /// A simple view to encapsulate what has gone wrong.
    @ViewBuilder
    public var body: some View {
        VStack {
            Text("The following errors are present:")
            ForEach(data, id: \.id) { warning in
                warning.display
            }
        }
    }
}
