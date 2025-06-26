//
//  SubCategory.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftData

/// Represents a category within a parent category that is used to group related transactions.
@Model
public final class SubCategory : BoundPair, UniqueElement, TransactionHolder, CategoryBase, Equatable {
    public convenience init() {
        self.init("")
    }
    public convenience init(parent: Category?) {
        self.init("", parent: parent)
    }
    /// Creates the sub category with a specified name, optional parent, and a series of associated transactions.
    public init(_ name: String, parent: Category? = nil, transactions: [LedgerEntry] = [], isLocked: Bool = false) {
        self.parent = parent
        self.name = name
        self.transactions = transactions
        self.isLocked = isLocked;
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
    public var isLocked: Bool;
    
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
    public func tryNewName(name: String, unique: UniqueEngine) -> Bool {
        let id = BoundPairID(parent: self.parentName, name: name)
        
        guard id != self.id else { return true; }
        
        return unique.subCategory(id: id, action: .validate)
    }
    public func setNewName(name: String, unique: UniqueEngine) {
        let id = BoundPairID(parent: parentName, name: name)
        
        guard id != self.id else { return }
        
        let _ = unique.subCategory(id: self.id, action: .remove)
        let _ = unique.subAccount(id: id, action: .insert)
        self.name = name
    }
    
    /// A UI ready filler data example of a sub-category.
    static let exampleSubCategory: SubCategory = .init("Utilities", parent: .init("Bills", children: []))
}
