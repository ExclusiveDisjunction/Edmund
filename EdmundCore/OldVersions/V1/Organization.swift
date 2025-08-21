//
//  Organization.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import Foundation
import SwiftData

extension EdmundModelsV1 {
    /// Represents the different kind of accounts for more dynamic choices on the UI.
    public enum AccountKind : Int, Identifiable, Hashable, Codable, CaseIterable {
        case credit, checking, savings, cd, trust, cash
        
        public var id: Self { self }
    }
    
    /// Represents a location to store money, via the use of inner sub-accounts.
    @Model
    public final class Account : Identifiable {
        public init(_ name: String, kind: AccountKind, creditLimit: Decimal?, interest: Decimal?, location: String?, children: [SubAccount]) {
            self.name = name;
            self.rawKind = kind.rawValue;
            self.location = location
            self.interest = interest
            self.rawCreditLimit = creditLimit;
            self.children = children
        }
        
        public static let objId: ObjectIdentifier = .init(Account.self)
        
        @Transient
        public var id: UUID = UUID();
        public var name: String = "";
        public private(set) var rawCreditLimit: Decimal? = nil;
        public var interest: Decimal? = nil;
        public var location: String? = nil;
        public private(set) var isVoided: Bool = false
        public private(set) var rawKind: Int = AccountKind.checking.rawValue;
        
        /// The children for this account. Money is not held in the account itself, it is held in the sub accounts.
        @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent)
        public var children: [SubAccount]
    }
    
    /// Represents a sub-section under an account for transaction grouping.
    @Model
    public final class SubAccount : Identifiable {
        /// Creates the sub account with a specified name, parent account, and a list of transactions.
        public init(_ name: String, parent: Account?, transactions: [LedgerEntry]) {
            self.name = name
            self.parent = parent
            self.transactions = transactions
        }
        
        @Transient
        public var id: UUID = UUID();
        public var name: String = "";
        public private(set) var isVoided: Bool = false
        
        @Relationship
        public var parent: Account? = nil;
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account)
        public var transactions: [LedgerEntry]? = nil;
        
        @Relationship(deleteRule: .nullify, inverse: \BudgetSavingsGoal.association)
        public var savingsGoals: [BudgetSavingsGoal] = [];
        
        @Relationship(deleteRule: .nullify, inverse: \IncomeDivision.depositTo)
        public var budgetInstances: [IncomeDivision] = [];
        @Relationship(deleteRule: .nullify, inverse: \AmountDevotion.account)
        public var amountDevotions: [AmountDevotion] = [];
        @Relationship(deleteRule: .nullify, inverse: \PercentDevotion.account)
        public var percentDevotions: [PercentDevotion] = [];
        @Relationship(deleteRule: .nullify, inverse: \RemainderDevotion.account)
        public var remainderDevotions: [RemainderDevotion] = [];
    }
    
    /// A grouping structure used to associate transactions into non-account groups.
    @Model
    public final class Category : Identifiable {
        /// Creates the category with a specified name and a list of children.
        public init(_ name: String, children: [SubCategory], isLocked: Bool) {
            self.name = name
            self.children = children;
            self.isLocked = isLocked
        }
        
        @Transient
        public var id: UUID = UUID();
        public var name: String = "";
        @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent)
        public var children: [SubCategory]
        public var isLocked: Bool;
    }
    
    /// Represents a category within a parent category that is used to group related transactions.
    @Model
    public final class SubCategory : Identifiable {
        /// Creates the sub category with a specified name, optional parent, and a series of associated transactions.
        public init(_ name: String, parent: Category?, transactions: [LedgerEntry], isLocked: Bool) {
            self.parent = parent
            self.name = name
            self.transactions = transactions
            self.isLocked = isLocked;
        }
        
        @Transient
        public var id: UUID = UUID();
        public var name: String = "";
        public var isLocked: Bool;
        
        @Relationship
        public var parent: Category? = nil;
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category)
        public var transactions: [LedgerEntry]? = nil;
        @Relationship(deleteRule: .nullify, inverse: \BudgetSpendingGoal.association)
        public var spendingGoals: [BudgetSpendingGoal] = [];
    }
}
