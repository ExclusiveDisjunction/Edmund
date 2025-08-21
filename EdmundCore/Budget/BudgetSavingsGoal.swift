//
//  BudgetSavingsGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftData
import Foundation

extension BudgetSavingsGoal : BudgetGoal {
    public convenience init(snapshot: BudgetGoalSnapshot<SubAccount>, unique: UniqueEngine) {
        self.init(
            account: snapshot.association,
            amount: snapshot.amount.rawValue,
            period: snapshot.period,
            parent: nil,
        )
    }
    
    public var period: MonthlyTimePeriods {
        get { MonthlyTimePeriods(rawValue: _period) ?? .monthly }
        set { _period = newValue.rawValue }
    }
    
    public func duplicate() -> BudgetSavingsGoal {
        .init(account: self.association, amount: self.amount, period: self.period, parent: nil)
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
        self.period = from.period
    }
}
