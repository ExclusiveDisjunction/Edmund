//
//  BudgetGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import SwiftData
import Observation

extension EdmundModelsV1 {
    public protocol BudgetGoal : Identifiable<UUID>, SnapshotableElement {
        associatedtype T: BoundPair & PersistentModel
        
        var amount: Decimal { get set }
        var association: T? { get set }
        var parent: BudgetMonth? { get set }
        
        func duplicate() -> Self;
    }
    
    @Model
    public final class BudgetSpendingGoal : BudgetGoal {
        public init(category: SubCategory?, amount: Decimal, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = category
            self.amount = amount
            self.parent = parent
        }
        
        public var id: UUID;
        public var amount: Decimal;
        @Relationship
        public var association: SubCategory?;
        @Relationship
        public var parent: BudgetMonth?;
        
        public func duplicate() -> BudgetSpendingGoal {
            .init(category: self.association, amount: self.amount, parent: nil)
        }
        
        public func makeSnapshot() -> BudgetGoalSnapshot<SubCategory> {
            return .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetGoalSnapshot<SubCategory> {
            return .init()
        }
        public func update(_ from: BudgetGoalSnapshot<SubCategory>, unique: UniqueEngine) {
            self.association = from.association
            self.amount = amount
        }
    }
    
    @Model
    public final class BudgetSavingsGoal : BudgetGoal {
        public init(account: SubAccount?, amount: Decimal, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = account
            self.amount = amount
            self.parent = parent
        }
        
        public var id: UUID;
        public var amount: Decimal;
        @Relationship
        public var association: SubAccount?;
        @Relationship
        public var parent: BudgetMonth?;
        
        public func duplicate() -> BudgetSavingsGoal {
            .init(account: self.association, amount: self.amount, parent: nil)
        }
        
        public func makeSnapshot() -> BudgetGoalSnapshot<SubAccount> {
            return .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetGoalSnapshot<SubAccount> {
            return .init()
        }
        public func update(_ from: BudgetGoalSnapshot<SubAccount>, unique: UniqueEngine) {
            self.association = from.association
            self.amount = amount
        }
    }
}

public typealias BudgetGoal = EdmundModelsV1.BudgetGoal
public typealias BudgetSpendingGoal = EdmundModelsV1.BudgetSpendingGoal
public typealias BudgetSavingsGoal = EdmundModelsV1.BudgetSavingsGoal

@Observable
public class BudgetGoalSnapshot<T> : ElementSnapshot where T: BoundPair {
    public init() {
        self.association = nil
        self.amount = .init()
    }
    public init<V>(_ data: V) where V: BudgetGoal, V.T == T {
        self.association = data.association
        self.amount = .init(rawValue: data.amount)
    }
    
    public var association: T?;
    public var amount: CurrencyValue;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        if association == nil {
            return .empty
        }
        
        if amount.rawValue < 0 {
            return .negativeAmount
        }
        
        return nil;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(association)
        hasher.combine(amount)
    }
    public static func ==(lhs: BudgetGoalSnapshot<T>, rhs: BudgetGoalSnapshot<T>) -> Bool {
        lhs.association == rhs.association && lhs.amount == rhs.amount
    }
}

public typealias BudgetSpendingGoalSnapshot = BudgetGoalSnapshot<SubCategory>;
public typealias BudgetSavingsGoalSnapshot = BudgetGoalSnapshot<SubAccount>;
