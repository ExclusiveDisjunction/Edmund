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
    public protocol BudgetGoal : Identifiable<UUID>, SnapshotableElement, SnapshotConstructableElement, PersistentModel {
        associatedtype T: BoundPair & PersistentModel
        
        var amount: Decimal { get set }
        var association: T? { get set }
        var parent: BudgetMonth? { get set }
        
        func duplicate() -> Self;
    }
}

public typealias BudgetGoal = EdmundModelsV1.BudgetGoal

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
