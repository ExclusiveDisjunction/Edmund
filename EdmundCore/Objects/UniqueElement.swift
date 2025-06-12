//
//  UniqueElement.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import Foundation
import SwiftUI

/// A quick overview of a property used to uniqueley identify a`UniqueElement`.
public struct ElementIdentifer : Identifiable, Equatable {
    public init(name: LocalizedStringKey, optional: Bool = false, id: UUID = UUID()) {
        self.id = id;
        self.name = name
        self.optional = optional
    }
    
    public var id: UUID;
    /// The name of the property. For example, 'Name'.
    public var name: LocalizedStringKey;
    /// If this type is optional or not. If it is optional, that means the value can be ommited from the owning type.
    public var optional: Bool;
    
    public static func == (lhs: ElementIdentifer, rhs: ElementIdentifer) -> Bool {
        lhs.name == rhs.name && lhs.optional == rhs.optional
    }
}

/// A protocol that determines if an element is unique.
/// For the unique pattern to work, the type must implement this protocol.
public protocol UniqueElement: Identifiable {
    /// A list of properties used to identify the data as unique.
    /// When an error about uniqueness is presented, the UI will include these values.
    static var identifiers: [ElementIdentifer] { get }
}
