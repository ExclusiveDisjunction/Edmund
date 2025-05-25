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
public final class Category : Identifiable, Hashable, BoundPairParent, NamedInspectableElement, NamedEditableElement {
    public typealias EditView = SimpleElementEdit<Category>
    public typealias Snapshot = SimpleElementSnapshot<Category>
    public typealias InspectorView = SimpleElementInspect<Category>
    
    public required init() {
        self.name = ""
        self.children = []
    }
    public init(_ name: String = "", children: [SubCategory] = []) {
        self.name = name
        self.children = children;
    }
    
    public static func ==(lhs: Category, rhs: Category) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public var id: String { name }
    public var name: String = "";
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent) public var children: [SubCategory]? = nil;

    public static var kind: NamedPairKind { .category }
    
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
    
    public var isEmpty: Bool {
        name.isEmpty
    }
}
@Model
public final class SubCategory : BoundPair, Equatable, NamedEditableElement, NamedInspectableElement, TransactionHolder {
    public typealias EditView = NamedPairChildEdit<SubCategory>
    public typealias Snapshot = NamedPairChildSnapshot<SubCategory>;
    public typealias InspectorView = SimpleElementInspect<SubCategory>;
    
    public required init() {
        self.parent = nil
        self.name = ""
        self.id = UUID()
        self.transactions = []
    }
    public required init(parent: Category?) {
        self.parent = parent
        self.name = ""
        self.id = UUID()
        self.transactions = []
    }
    public init(_ name: String, parent: Category? = nil, id: UUID = UUID(), transactions: [LedgerEntry] = []) {
        self.parent = parent
        self.name = name
        self.id = id
        self.transactions = transactions
    }
    
    public static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(name)
    }
    
    public var id: UUID = UUID();
    public var name: String = "";
    @Relationship public var parent: Category? = nil;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category) public var transactions: [LedgerEntry]? = nil;

    public var isEmpty: Bool {
        parent?.isEmpty ?? false || name.isEmpty
    }
    
    public static var kind: NamedPairKind {
        get { .category }
    }
    
    static let exampleSubCategory: SubCategory = .init("Utilities", parent: .init("Bills"))
}
