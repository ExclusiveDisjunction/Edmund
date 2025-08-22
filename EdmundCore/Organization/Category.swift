//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

extension Category : UniqueElement, DefaultableElement, NamedElement, TransactionHolder, Equatable, CustomStringConvertible {
    public convenience init() {
        self.init("")
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
    
    public func tryNewName(name: String, unique: UniqueEngine) async -> Bool {
        guard name != self.name else { return true }
        
        return await unique.isIdOpen(key: .init(Category.self), id: name)
    }
    public func setNewName(name: String, unique: UniqueEngine) async {
        guard name != self.name else { return }
        guard await unique.swapId(key: .init(Category.self), oldId: self.name, newId: name) else {
            fatalError("The unique engine could not swap the id for the category formally known as \(self.name)")
        }
        
        self.name = name
    }
    
    /// A list of categories that can be used to display filler data.
    @MainActor
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
    @MainActor
    public static var exampleCategory: Category {
        .init("Bills")
    }
}
