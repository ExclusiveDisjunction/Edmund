//
//  Organization.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV2 {
    /// Represents a location to store money, via the use of inner sub-accounts.
    @Model
    public final class Account : Identifiable {
        public init(_ name: String, kind: AccountKind = .checking, creditLimit: Decimal? = nil, interest: Decimal? = nil, location: String? = nil) {
            self.name = name;
            self.location = location
            self.interest = interest
            self.kind = kind;
            self._creditLimit = creditLimit;
            self.id = UUID();
        }
        
        public var id: UUID = UUID();
        /// The account's name. This must be unique. This can be simple like "Checking", or more elaborate like "Chase Savings"
        public var name: String = "";
        /// An optional interest value
        public var interest: Decimal? = nil;
        /// An optional description of where the account is physically
        public var location: String? = nil;
        public internal(set) var isVoided: Bool = false
        /// The kind of account, used to make swift data happy.
        public var kind: AccountKind = AccountKind.checking;
        /// The credit limit stored within the system. It will only be provided and active if the account kind is `.credit`.
        public internal(set) var _creditLimit: Decimal? = nil;
        
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account)
        public var transactions: [LedgerEntry] = [];
        
        @Relationship(deleteRule: .nullify, inverse: \BudgetSavingsGoal.association)
        public var savingsGoals: [BudgetSavingsGoal] = [];
        
        @Relationship(deleteRule: .nullify, inverse: \IncomeDivision.depositTo)
        public var incomeDivisions: [IncomeDivision] = [];
        @Relationship(deleteRule: .nullify, inverse: \IncomeDevotion.account)
        public var devotions: [IncomeDevotion] = [];
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

        public var id: UUID = UUID();
        public var name: String = "";
        public var desc: String = "";
        public var isLocked: Bool = false;
        
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.category)
        public var transactions: [LedgerEntry];
        @Relationship(deleteRule: .nullify, inverse: \BudgetSpendingGoal.association)
        public var spendingGoals: [BudgetSpendingGoal] = [];
    }
}
