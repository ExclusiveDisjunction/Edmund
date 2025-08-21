//
//  BudgetSpendingGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftData
import Foundation

extension BudgetSpendingGoal : BudgetGoal {
    public convenience init(snapshot: BudgetGoalSnapshot<SubCategory>, unique: UniqueEngine) {
        self.init(
            category: snapshot.association,
            amount: snapshot.amount.rawValue,
            period: snapshot.period,
            parent: nil,
        )
    }
    
    public var period: MonthlyTimePeriods {
        get { MonthlyTimePeriods(rawValue: _period) ?? .monthly }
        set { _period = newValue.rawValue }
    }
    
    public func duplicate() -> BudgetSpendingGoal {
        .init(category: self.association, amount: self.amount, period: self.period, parent: nil)
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
