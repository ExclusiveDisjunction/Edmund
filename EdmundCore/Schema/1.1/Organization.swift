//
//  Organization.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    /// Represents a location to store money, via the use of inner sub-accounts.
    @Model
    public final class Account {
        public init(_ name: String, kind: AccountKind = .checking, creditLimit: Decimal? = nil, interest: Decimal? = nil, location: String? = nil, children: [SubAccount] = []) {
            self.name = name;
            self._kind = kind.rawValue;
            self.location = location
            self.interest = interest
            self._creditLimit = creditLimit;
            self.children = children
        }
        /// Migrates from a previous version `Account`.
        ///
        /// This migrates all properties of the account, and migrates the `SubAccount`s within, but do note the migrations carried by `SubAccount(migration:parent:)`.
        public init(migration: EdmundModelsV1.Account) {
            self.name = migration.name
            self._kind = migration.rawKind
            self.location = migration.location
            self.interest = migration.interest
            self._creditLimit = migration.rawCreditLimit
            self.isVoided = migration.isVoided
            self.children = [] //need to so that the compiler doesnt fuss that `this` is un-init
            
            self.children = migration.children.map { SubAccount(migration: $0, parent: self) }
        }
        
        /// The account's name. This must be unique. This can be simple like "Checking", or more elaborate like "Chase Savings"
        public var name: String = "";
        /// The credit limit stored within the system. It will only be provided and active if the account kind is `.credit`.
        public internal(set) var _creditLimit: Decimal? = nil;
        /// An optional interest value
        public var interest: Decimal? = nil;
        /// An optional description of where the account is physically
        public var location: String? = nil;
        public internal(set) var isVoided: Bool = false
        /// The kind of account, used to make swift data happy.
        public internal(set) var _kind: AccountKind.RawValue;
        
        /// The children for this account. Money is not held in the account itself, it is held in the sub accounts.
        @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent)
        public var children: [SubAccount]
    }
    
    /// Represents a sub-section under an account for transaction grouping.
    @Model
    public final class SubAccount {
        /// Creates the sub account with a specified name, parent account, and a list of transactions.
        public init(_ name: String, parent: Account? = nil, transactions: [LedgerEntry] = []) {
            self.name = name
            self.parent = parent
            self.transactions = transactions
        }
        /// Migrates from a previous version `SubAccount`.
        ///
        /// This does not migrate:
        /// 1. Transactions (due to joint effort with `SubCategory`)
        /// 2. Savings Goals (due to joint effort with `BudgetMonth`)
        /// 3. Income Divisions (due to joint effort with its devotion types)
        /// 4. Amount Devotions, Percent Devotions, and Remainder Devotions (due to joint effort with `IncomeDivision`)
        public init(migration: EdmundModelsV1.SubAccount, parent: Account) {
            self.name = name
            self.parent = parent
            self.isVoided = migration.isVoided
        }
        
        public var name: String = "";
        public internal(set) var isVoided: Bool = false
        @Relationship
        public var parent: Account? = nil;
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account)
        public var transactions: [LedgerEntry]? = nil;
        
        @Relationship(deleteRule: .nullify, inverse: \BudgetSavingsGoal.association)
        public var savingsGoals: [BudgetSavingsGoal] = [];
        
        @Relationship(deleteRule: .nullify, inverse: \IncomeDivision.depositTo)
        public var incomeDivisions: [IncomeDivision] = [];
        @Relationship(deleteRule: .nullify, inverse: \AmountDevotion.account)
        public var amountDevotions: [AmountDevotion] = [];
        @Relationship(deleteRule: .nullify, inverse: \PercentDevotion.account)
        public var percentDevotions: [PercentDevotion] = [];
        @Relationship(deleteRule: .nullify, inverse: \RemainderDevotion.account)
        public var remainderDevotions: [RemainderDevotion] = [];
    }
    
    /// A grouping structure used to associate transactions into non-account groups.
    @Model
    public final class Category {
        /// Creates the category with a specified name and a list of children.
        public init(_ name: String, children: [SubCategory] = [], isLocked: Bool = false) {
            self.name = name
            self.children = children;
            self.isLocked = isLocked
        }
        /// Migrates from a previous version of `Category`.
        ///
        /// This will carry over all properties, however, note the `SubCategory(migration:parent:)` migration criteria.
        public init(migration: EdmundModelsV1.Category) {
            self.name = migration.name
            self.isLocked = migration.isLocked
            self.children = []
            
            self.children = migration.children.map { SubCategory(migration: $0, parent: self) }
        }
        
        public var name: String = "";
        @Relationship(deleteRule: .cascade, inverse: \SubCategory.parent)
        public var children: [SubCategory]
        public var isLocked: Bool;
    }
    
    /// Represents a category within a parent category that is used to group related transactions.
    @Model
    public final class SubCategory {
        /// Creates the sub category with a specified name, optional parent, and a series of associated transactions.
        public init(_ name: String, parent: Category? = nil, transactions: [LedgerEntry] = [], isLocked: Bool = false) {
            self.parent = parent
            self.name = name
            self.transactions = transactions
            self.isLocked = isLocked;
        }
        /// Migrates from a previous version `SubCategory`.
        ///
        /// This does not migrate:
        /// 1. Transactions (due to joint effort with `SubAccount`)
        /// 2. Spending Goals (due to joint effort with `BudgetMonth`)
        public init(migration: EdmundModelsV1.SubCategory, parent: Category) {
            self.name = migration.name
            self.isLocked = migration.isLocked
            self.parent = parent
        }
        
        /// The name of the sub-category
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
