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
    @Model
    public class BudgetGoal<T> : Identifiable, SnapshotableElement where T: BoundPair, T: PersistentModel {
        public init(category: T?, amount: Decimal, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.category = category
            self.amount = amount
            self.parent = parent
        }
        
        public var id: UUID;
        public var amount: Decimal;
        @Relationship
        public var category: T?;
        @Relationship
        public var parent: BudgetMonth?;
        
        public func duplicate() -> BudgetGoal<T> {
            .init(category: self.category, amount: self.amount, parent: nil)
        }
        
        public func makeSnapshot() -> BudgetGoalSnapshot<T> {
            return .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetGoalSnapshot<T> {
            return .init()
        }
        public func update(_ from: BudgetGoalSnapshot<T>, unique: UniqueEngine) {
            self.category = from.category
            self.amount = amount
        }
    }
    
    public typealias BudgetSpendingGoal = BudgetGoal<SubCategory>;
    public typealias BudgetSavingsGoal = BudgetGoal<SubAccount>;
}

public typealias BudgetGoal = EdmundModelsV1.BudgetGoal;
public typealias BudgetSpendingGoal = EdmundModelsV1.BudgetSpendingGoal
public typealias BudgetSavingsGoal = EdmundModelsV1.BudgetSavingsGoal

@Observable
public class BudgetGoalSnapshot<T> : ElementSnapshot where T: BoundPair {
    public init() {
        self.category = nil
        self.amount = .init()
    }
    public init(_ data: BudgetGoal<T>) {
        self.category = data.category
        self.amount = .init(rawValue: data.amount)
    }
    
    public var category: T?;
    public var amount: CurrencyValue;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        if category == nil {
            return .empty
        }
        
        if amount.rawValue < 0 {
            return .negativeAmount
        }
        
        return nil;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(category)
        hasher.combine(amount)
    }
    public static func ==(lhs: BudgetGoalSnapshot<T>, rhs: BudgetGoalSnapshot<T>) -> Bool {
        lhs.category == rhs.category && lhs.amount == rhs.amount
    }
}

public typealias BudgetSpendingGoalSnapshot = BudgetGoalSnapshot<SubCategory>;
public typealias BudgetSavingsGoalSnapshot = BudgetGoalSnapshot<SubAccount>;
