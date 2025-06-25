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
public final class Category : Identifiable, Hashable, BoundPairParent, NamedInspectableElement, NamedEditableElement, UniqueElement {
    public typealias EditView = CategoryEdit
    public typealias Snapshot = CategorySnapshot
    public typealias InspectorView = CategoryInspect
    
    public init() {
        self.name = ""
        self.children = []
    }
    /// Creates the category with a specified name and a list of children.
    public init(_ name: String, children: [SubCategory] = []) {
        self.name = name
        self.children = children;
    }
    
    public var id: String { name }
    public var name: String = "";
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent)
    public var children: [SubCategory]
    
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
            .init("Utilities"),
            .init("Subscriptions"),
            .init("Bills")
        ])
    }()
}

@Observable
public final class CategorySnapshot: ElementSnapshot {
    public typealias For = Category;
    
    public init() {
        self.name = ""
    }
    public init(_ from: Category) {
        self.name = from.name
    }
    
    public var name: String;
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        let name = name.trimmingCharacters(in: .whitespaces);
        
        if !unique.category(id: name, action: .validate) { return [.unique(Category.identifiers)] }
        else if name.isEmpty { return [.empty("Name")] }
        else { return [] }
    }
    public func apply(_ to: Category, context: ModelContext, unique: UniqueEngine) throws(UniqueFailueError<String>) {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard unique.category(id: name, action: .insert) else { throw .init(value: name) }
        
        to.name = name;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    public static func ==(lhs: CategorySnapshot, rhs: CategorySnapshot) -> Bool {
        lhs.name == rhs.name
    }
}
