//
//  NamedPairKind.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData
import SwiftUI

/// The ID used to identify a specific `BoundPair` value. It contains an optional parent name, and a specified name.
public struct BoundPairID : Hashable, Equatable, RawRepresentable, Sendable, CustomStringConvertible {
    /// Creates the ID using an optional parent name, and the child's name.
    public init(parent: String?, name: String) {
        self.parent = parent
        self.name = name
    }
    public init?(rawValue: String) {
        let split = rawValue.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) };
        guard split.count == 2 else { return nil }
        guard !split[1].isEmpty else { return nil } //The parent name can be empty, in which it is assume to be nil.
        
        self.parent = split[0].isEmpty ? nil : split[0];
        self.name = split[1];
    }
    
    /// The associated parent name, as an optional value.
    public let parent: String?;
    /// The associated name
    public let name: String;
    public var rawValue: String {
        "\(parent ?? String()).\(name)"
    }
    
    public var description: String {
        self.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(name)
    }
    public static func ==(lhs: BoundPairID, rhs: BoundPairID) -> Bool {
        lhs.parent == rhs.parent && lhs.name == rhs.name
    }
}

/// Represents a basis used between bound pair parents and bound pairs.
public protocol PairBasis : Identifiable, PersistentModel, Hashable, Equatable {
    /// The name of the element
    var name: String { get set }
}

/// Represents a type that parents a `BoundPair` value.
public protocol BoundPairParent : PairBasis, Identifiable<String> {
    /// The child type that this type parents.
    associatedtype C: BoundPair;
    
    /// Creates a default, empty initializer.
    init();
    
    var children: [C] { get set }
}

/// A type that has a specific parent, and a name.
public protocol BoundPair : PairBasis, Identifiable<BoundPairID> {
    /// The parent type
    associatedtype P: BoundPairParent;
    
    /// Creates a blank version of this pair. This will set the parent to `nil`.
    init();
    /// Creates a blank version of this pair with a specified parent.
    init(parent: P?);
    
    /// The parented value of this type
    var parent: P? { get set }
}
public extension BoundPair {
    /// Compares two bound pairs and determines if they have the same parent & child name.
    func eqByName(_ rhs: any BoundPair) -> Bool {
        self.parentName == rhs.parentName && self.name == rhs.name
    }
    
    /// Returns the parent's name, if the parent is provided.
    var parentName: String? {
        get { parent?.name }
        set(v) {
            if let parent = self.parent, let value = v {
                parent.name = value
            }
        }
    }
}

public extension Array where Element: BoundPair {
    /// Finds a specfied bound pair using a parent name and child name.
    func findPair(_ parent: String, _ child: String) -> Element? {
        self.first(where: {$0.name == child && $0.parentName == parent } )
    }
}
public extension Array where Element: BoundPairParent {
    /// Finds a specified bound pair using a parnet name and child name.
    func findPair(_ parent: String, _ child: String) -> Element.C? {
        guard let foundParent = self.first(where: {$0.name == parent } ) else { return nil }
        
        return foundParent.children.first(where: {$0.name == child } )
    }
}
