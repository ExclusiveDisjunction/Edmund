//
//  BudgetGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import SwiftData
import Observation

public protocol BudgetGoal : Identifiable<UUID>, SnapshotableElement, SnapshotConstructableElement, PersistentModel {
    associatedtype T: BoundPair & PersistentModel
    
    var amount: Decimal { get set }
    var period: MonthlyTimePeriods { get set }
    var association: T? { get set }
    var parent: BudgetMonth? { get set }

    func duplicate() -> Self;
}

public extension BudgetGoal {
    var monthlyGoal : Decimal {
        self.amount * period.conversionFactor(.monthly)
    }
}

@Observable
public class BudgetGoalSnapshot<T> : ElementSnapshot where T: BoundPair {
    public init() {
        self.association = nil
        self.period = .monthly
        self.amount = .init()
    }
    public init<V>(_ data: V) where V: BudgetGoal, V.T == T {
        self.association = data.association
        self.period = data.period
        self.amount = .init(rawValue: data.amount)
    }
    
    public var association: T?;
    public var amount: CurrencyValue;
    public var period: MonthlyTimePeriods;
    public var monthlyGoal: Decimal {
        amount.rawValue * period.conversionFactor(.monthly)
    }
    
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
        hasher.combine(period)
    }
    public static func ==(lhs: BudgetGoalSnapshot<T>, rhs: BudgetGoalSnapshot<T>) -> Bool {
        lhs.association == rhs.association && lhs.amount == rhs.amount && lhs.period == rhs.period
    }
}

public typealias BudgetSpendingGoalSnapshot = BudgetGoalSnapshot<SubCategory>;
public typealias BudgetSavingsGoalSnapshot = BudgetGoalSnapshot<SubAccount>;
