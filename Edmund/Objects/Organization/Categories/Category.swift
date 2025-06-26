//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

/// A grouping structure used to associate transactions into non-account groups.
@Model
public final class Category : CategoryBase, BoundPairParent, UniqueElement, Equatable {
    public init() {
        self.name = ""
        self.children = []
        self.isLocked = true
    }
    /// Creates the category with a specified name and a list of children.
    public init(_ name: String, children: [SubCategory] = [], isLocked: Bool = false) {
        self.name = name
        self.children = children;
        self.isLocked = isLocked
    }
    
    public var id: String { name }
    public var name: String = "";
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent)
    public var children: [SubCategory]
    public var isLocked: Bool;
    
    public static func ==(lhs: Category, rhs: Category) -> Bool {
        lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Category",
            plural:   "Categories",
            inspect:  "Inspect Category",
            edit:     "Edit Category",
            add:      "Add Category"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Name") ]
    }
    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.category(id: self.id, action: .remove)
    }
    public func tryNewName(name: String, unique: UniqueEngine) -> Bool {
        guard name != self.name else { return true }
        
        return unique.category(id: name, action: .validate)
    }
    public func setNewName(name: String, unique: UniqueEngine) {
        guard name != self.name else { return }
        
        let _ = unique.category(id: self.name, action: .remove);
        let _ = unique.category(id: name, action: .insert);
        self.name = name;
    }
    
    /// A list of categories that can be used to display filler data.
    public static let exampleCategories: [Category] = {
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
    }()
    /// A singular category that can be used to display filler data.
    public static let exampleCategory: Category = {
        .init("Bills", children: [
            .init("Utility"),
            .init("Subscription"),
            .init("Bill")
        ])
    }()
}
