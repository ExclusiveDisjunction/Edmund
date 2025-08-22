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
    public final class Account : Identifiable {
        public init(_ name: String, kind: AccountKind = .checking, creditLimit: Decimal? = nil, interest: Decimal? = nil, location: String? = nil) {
            self.name = name;
            self.location = location
            self.interest = interest
            self._kind = kind.rawValue;
            self._creditLimit = creditLimit;
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
        }
        
        @Transient
        public var id: UUID = UUID();
        
        /// The account's name. This must be unique. This can be simple like "Checking", or more elaborate like "Chase Savings"
        public var name: String = "";
        /// An optional interest value
        public var interest: Decimal? = nil;
        /// An optional description of where the account is physically
        public var location: String? = nil;
        public internal(set) var isVoided: Bool = false
        /// The kind of account, used to make swift data happy.
        public internal(set) var _kind: AccountKind.RawValue;
        /// The credit limit stored within the system. It will only be provided and active if the account kind is `.credit`.
        public internal(set) var _creditLimit: Decimal? = nil;
        
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account)
        public var transactions: [LedgerEntry] = [];
        
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
    public final class Category : Identifiable {
        /// Creates the category with a specified name and a list of children.
        public init(_ name: String, desc: String = "", isLocked: Bool = false) {
            self.name = name
            self.desc = desc
            self.isLocked = isLocked
            self.transactions = []
        }
        /// Migrates from a previous version of `Category`.
        ///
        /// This will carry over all properties, however, note the `SubCategory(migration:parent:)` migration criteria.
        public init(migration: EdmundModelsV1.Category) {
            self.name = migration.name
            self.isLocked = migration.isLocked
            self.desc = ""
            
            self.transactions = []
            self.spendingGoals = []
        }
        
        @Transient
        public var id: UUID = UUID();
        
        public var name: String;
        public var desc: String;
        public var isLocked: Bool;
        
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category)
        public var transactions: [LedgerEntry];
        @Relationship(deleteRule: .nullify, inverse: \BudgetSpendingGoal.association)
        public var spendingGoals: [BudgetSpendingGoal] = [];
    }
}
