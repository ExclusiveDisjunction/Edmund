//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

extension EdmundModelsV1_1 {
    /// A grouping structure used to associate transactions into non-account groups.
    @Model
    public final class Category : CategoryBase, BoundPairParent, UniqueElement, NamedElement, Equatable, CustomStringConvertible {
        public init() {
            self.name = ""
            self.children = []
            self.isLocked = false
        }
        /// Creates the category with a specified name and a list of children.
        public init(_ name: String, children: [SubCategory] = [], isLocked: Bool = false) {
            self.name = name
            self.children = children;
            self.isLocked = isLocked
        }
        
        public static let objId: ObjectIdentifier = .init(Category.self)
        
        public var id: String { name }
        public var name: String = "";
        @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent)
        public var children: [SubCategory]
        public var isLocked: Bool;
        
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
                .init("Account Control", children: [
                    .init("Transfer"),
                    .init("Pay"),
                    .init("Audit"),
                    .init("Initial")
                ]),
                .init("Personal", children: [
                    .init("Dining"),
                    .init("Entertainment")
                ]),
                .init("Home", children: [
                    .init("Groceries"),
                    .init("Health"),
                    .init("Decor"),
                    .init("Repairs")
                ]),
                .init("Car", children: [
                    .init("Gas"),
                    .init("Maintenence"),
                    .init("Decor")
                ])
            ]
        }
        /// A singular category that can be used to display filler data.
        @MainActor
        public static var exampleCategory: Category {
            .init("Bills", children: [
                .init("Utility"),
                .init("Subscription"),
                .init("Bill")
            ])
        }
    }
}

public typealias Category = EdmundModelsV1_1.Category
