//
//  BudgetGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import SwiftData
import Observation

public enum MonthlyTimePeriods : Int, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case weekly = 0
    case biWeekly = 1
    case monthly = 2
    
    private var index: Int {
        self.rawValue
    }
    private static let facTable: [[Decimal]] =
        [
        //   Week,  Bi-Week, Month
            [ 1.0,  2.0,     4.0 ],
            [ 0.5,  1.0,     2.0 ],
            [ 0.25, 0.5,     1.0 ]
        ];
    
    public func conversionFactor(_ to: MonthlyTimePeriods) -> Decimal {
        let i = self.index, j = to.index;
        
        return Self.facTable[i][j];
    }
    public var asComponents: DateComponents {
        switch self {
            case .weekly:      .init(weekOfYear: 1)
            case .biWeekly:    .init(weekOfYear: 2)
            case .monthly:     .init(month: 1)
        }
    }
    
    public var id: Self { self }
}

extension EdmundModelsV1_1 {
    public protocol BudgetGoal : Identifiable<UUID>, SnapshotableElement, SnapshotConstructableElement, PersistentModel {
        associatedtype T: BoundPair & PersistentModel
        
        var amount: Decimal { get set }
        var period: MonthlyTimePeriods { get set }
        var association: T? { get set }
        var parent: BudgetMonth? { get set }
    
        func duplicate() -> Self;
    }
}

public extension EdmundModelsV1_1.BudgetGoal {
    var monthlyGoal : Decimal {
        self.amount * period.conversionFactor(.monthly)
    }
}

public typealias BudgetGoal = EdmundModelsV1_1.BudgetGoal

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
