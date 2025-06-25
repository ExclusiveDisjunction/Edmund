//
//  SubCategory.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftData

/// Represents a category within a parent category that is used to group related transactions.
@Model
public final class SubCategory : BoundPair, Equatable, NamedEditableElement, NamedInspectableElement, UniqueElement, TransactionHolder {
    public typealias EditView = BoundPairChildEdit<SubCategory>
    public typealias Snapshot = SubCategorySnapshot;
    public typealias InspectorView = BoundPairChildInspect<SubCategory>;
    
    public convenience init() {
        self.init("")
    }
    public convenience init(parent: Category?) {
        self.init("", parent: parent)
    }
    /// Creates the sub category with a specified name, optional parent, and a series of associated transactions.
    public init(_ name: String, parent: Category? = nil, transactions: [LedgerEntry] = []) {
        self.parent = parent
        self.name = name
        self.transactions = transactions
    }
    
    public var id: BoundPairID {
        .init(parent: self.parentName, name: self.name)
    }
    /// The name of the sub-category
    public var name: String = "";
    @Relationship
    public var parent: Category? = nil;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category)
    public var transactions: [LedgerEntry]? = nil;
    
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
    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.subCategory(id: self.id, action: .remove)
    }
    
    /// A UI ready filler data example of a sub-category.
    static let exampleSubCategory: SubCategory = .init("Utilities", parent: .init("Bills", children: []))
}

/// The snapshot type for `SubCategory`.
@Observable
public final class SubCategorySnapshot: ElementSnapshot, BoundPairSnapshot {
    public typealias Host = SubCategory;
    public typealias Parent = Category;
    
    public init() {
        self.name = "";
        self.parent = nil;
    }
    public init(_ from: SubCategory) {
        self.name = from.name;
        self.parent = from.parent
    }
    
    /// The sub-category's name
    public var name: String;
    /// The sub-category's parent account
    public var parent: Category?;
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result: [ValidationFailure] = [];
        
        let name = name.trimmingCharacters(in: .whitespaces);
        let id = BoundPairID(parent: parent?.name, name: name)
        
        if !unique.subAccount(id: id, action: .validate) { result.append(.unique(SubAccount.identifiers)) }
        if name.isEmpty { result.append(.empty("Name")) }
        if parent == nil { result.append(.empty("Category")) }
        
        return result;
    }
    public func apply(_ to: SubCategory, context: ModelContext, unique: UniqueEngine) throws(UniqueFailueError<BoundPairID>) {
        let name = self.name.trimmingCharacters(in: .whitespaces)
        let id = BoundPairID(parent: parent?.name, name: name)
        
        guard unique.subAccount(id: id, action: .insert) else { throw .init(value: id) }
        
        to.name = name
        to.parent = parent
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    public static func ==(lhs: SubCategorySnapshot, rhs: SubCategorySnapshot) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
}
