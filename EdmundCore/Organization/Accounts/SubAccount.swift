//
//  SubAccount.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/20/25.
//

import Foundation
import SwiftData

extension EdmundModelsV1_1 {
    /// Represents a sub-section under an account for transaction grouping.
    @Model
    public final class SubAccount : BoundPair, Equatable, UniqueElement, NamedElement, VoidableElement, TransactionHolder, CustomStringConvertible {
        public convenience init() {
            self.init("")
        }
        public convenience init(parent: Account?) {
            self.init("", parent: parent)
        }
        /// Creates the sub account with a specified name, parent account, and a list of transactions.
        public init(_ name: String, parent: Account? = nil, transactions: [LedgerEntry] = []) {
            self.name = name
            self.parent = parent
            self.transactions = transactions
        }
        
        public static let objId: ObjectIdentifier = .init(SubAccount.self)
        
        public var id: BoundPairID {
            .init(parent: self.parentName, name: self.name)
        }
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
        
        public func setVoidStatus(_ new: Bool) {
            guard new != isVoided else {
                return;
            }
            
            if new {
                self.isVoided = true;
                transactions?.forEach { $0.setVoidStatus(true) }
            }
            else {
                self.isVoided = false;
            }
        }
        
        public var description: String {
            "Sub Account \(id)"
        }
        
        @MainActor
        public func tryNewName(name: String, unique: UniqueEngine) async -> Bool {
            let newId = BoundPairID(parent: self.parentName, name: name)
            
            guard newId != self.id else { return true; }
            
            return await unique.isIdOpen(key: .init(SubAccount.self), id: newId)
        }
        @MainActor
        public func takeNewName(name: String, unique: UniqueEngine) async throws(UniqueFailureError<BoundPairID>) {
            guard name != self.name else {
                return;
            }
            
            let newId = BoundPairID(parent: self.parentName, name: name)
            let result = await unique.swapId(key: Self.objId, oldId: self.id, newId: newId)
            guard result else {
                throw .init(value: newId)
            }
            
            self.name = name;
        }
        
        public static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
            lhs.name == rhs.name && lhs.parent == rhs.parent
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(parent)
        }
        
        /// An example sub account
        public static var exampleSubAccount: SubAccount {
            .init("DI", parent: .init("Checking"))
        }
    }
}

public typealias SubAccount = EdmundModelsV1_1.SubAccount
