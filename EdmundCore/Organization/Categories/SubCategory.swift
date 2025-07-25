//
//  SubCategory.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftData

extension EdmundModelsV1 {
    /// Represents a category within a parent category that is used to group related transactions.
    @Model
    public final class SubCategory : BoundPair, UniqueElement, TransactionHolder, CategoryBase, NamedElement, Equatable, CustomStringConvertible {
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
        
        public static let objId: ObjectIdentifier = .init(SubCategory.self)
        
        public var id: BoundPairID {
            .init(parent: self.parentName, name: self.name)
        }
        /// The name of the sub-category
        public var name: String = "";
        @Relationship
        public var parent: Category? = nil;
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category)
        public var transactions: [LedgerEntry]? = nil;
        @Relationship(deleteRule: .nullify, inverse: \BudgetSpendingGoal.parent)
        public var spendingGoals: [BudgetSpendingGoal] = [];
        public var isLocked: Bool;
        
        public var description: String {
            "Sub Category \(id)"
        }
        
        public static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
            lhs.id == rhs.id
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(parent)
            hasher.combine(name)
        }
        
        @MainActor
        public func tryNewName(name: String, unique: UniqueEngine) async -> Bool {
            let id = BoundPairID(parent: self.parentName, name: name)
            
            guard id != self.id else { return true; }
            
            return await unique.isIdOpen(key: .init(SubCategory.self), id: id)
        }
        @MainActor
        public func setNewName(name: String, unique: UniqueEngine) async {
            let id = BoundPairID(parent: parentName, name: name)
            
            guard id != self.id else { return }
            guard await unique.swapId(key: .init(SubCategory.self), oldId: self.id, newId: id) else {
                fatalError("The unique engine was not able to bind to the new name provided.")
            }
            
            self.name = name
        }
        
        /// A UI ready filler data example of a sub-category.
        @MainActor
        public static var exampleSubCategory: SubCategory = .init("Utilities", parent: .init("Bills", children: []))
    }
}

public typealias SubCategory = EdmundModelsV1.SubCategory
