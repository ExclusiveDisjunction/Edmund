//
//  Categories.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
public final class Category : Identifiable, Hashable, BoundPairParent, NamedInspectableElement, NamedEditableElement, UniqueElement {
    public typealias EditView = SimpleElementEdit<Category>
    public typealias Snapshot = SimpleElementSnapshot<Category>
    public typealias InspectorView = SimpleElementInspect<Category>
    
    public init() {
        self.name = ""
        self.children = []
    }
    public init(_ name: String = "", children: [SubCategory] = []) {
        self.name = name
        self.children = children;
    }
    
    public var id: String { name }
    public var name: String = "";
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent) public var children: [SubCategory]? = nil;
    
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
    public static let exampleCategory: Category = {
        .init("Bills", children: [
            .init("Utilities"),
            .init("Subscriptions"),
            .init("Bills")
        ])
    }()
}
@Model
public final class SubCategory : BoundPair, Equatable, NamedEditableElement, NamedInspectableElement, UniqueElement, TransactionHolder {
    public typealias EditView = NamedPairChildEdit<SubCategory>
    public typealias Snapshot = NamedPairChildSnapshot<SubCategory>;
    public typealias InspectorView = SimpleElementInspect<SubCategory>;
    
    public convenience init() {
        self.init("")
    }
    public convenience init(parent: Category?) {
        self.init("", parent: parent)
    }
    public init(_ name: String, parent: Category? = nil, transactions: [LedgerEntry] = []) {
        self.parent = parent
        self.name = name
        self.transactions = transactions
    }
    
    public var id: String {
        "\(parent_name ?? "").\(name)"
    }
    public var name: String = "";
    @Relationship public var parent: Category? = nil;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category) public var transactions: [LedgerEntry]? = nil;
    
    public static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(name)
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Sub Category",
            plural:   "Sub Categories",
            inspect:  "Inspect Sub Category",
            edit:     "Edit Sub Category",
            add:      "Add Sub Category"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Parent Name", optional: true), .init(name: "Name") ]
    }
    
    static let exampleSubCategory: SubCategory = .init("Utilities", parent: .init("Bills"))
}
