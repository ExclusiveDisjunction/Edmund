//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

extension Category : UniqueElement, DefaultableElement, NamedElement, SnapshotConstructableElement, TransactionHolder, Equatable, CustomStringConvertible {
    public convenience init() {
        self.init("")
    }
    public convenience init(snapshot: CategorySnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        self.init()
        try await self.update(snapshot, unique: unique)
    }
    
    public static let objId: ObjectIdentifier = .init(Category.self)
    
    public var uID: String { name }
    public var description: String {
        "Category \(name)"
    }
    
    public static func ==(lhs: Category, rhs: Category) -> Bool {
        lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public func makeSnapshot() -> CategorySnapshot {
        CategorySnapshot(self)
    }
    public static func makeBlankSnapshot() -> CategorySnapshot {
        CategorySnapshot()
    }
    public func update(_ from: CategorySnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        let name = from.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = from.desc.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if name != self.name {
            guard await unique.swapId(key: Self.objId, oldId: self.name, newId: name) else {
                throw .init(value: name)
            }
        }
        
        self.name = name
        self.desc = desc
    }
    
    /// A list of categories that can be used to display filler data.
    public static var exampleCategories: [Category] {
        [
            exampleCategory,
            .init("Transfers"),
            .init("Income"),
            .init("Adjustments"),
            .init("Personal"),
            .init("Groceries"),
            .init("Health"),
            .init("Home"),
            .init("Car")
        ]
    }
    /// A singular category that can be used to display filler data.
    public static var exampleCategory: Category {
        .init("Bills")
    }
}

@Observable
public final class CategorySnapshot : ElementSnapshot {
    public init() {
        self.name = ""
        self.oldName = ""
        self.desc = ""
    }
    public init(_ from: Category) {
        self.name = from.name
        self.oldName = from.name
        self.desc = from.desc
    }
    
    @ObservationIgnored public let oldName: String;
    public var name: String;
    public var desc: String;
    
    public func validate(unique: UniqueEngine) async -> ValidationFailure? {
        let name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty else {
            return .empty
        }
        
        if name != oldName {
            guard await unique.isIdOpen(key: Category.objId, id: name) else {
                return .unique
            }
        }
        
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(desc)
    }
    public static func == (lhs: CategorySnapshot, rhs: CategorySnapshot) -> Bool {
        lhs.name == rhs.name && lhs.desc == rhs.desc
    }
}
