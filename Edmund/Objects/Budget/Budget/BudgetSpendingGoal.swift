//
//  BudgetSpendingGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftData
import Foundation

extension BudgetSpendingGoal : SnapshotConstructableElement {
    public convenience init(snapshot: BudgetGoalSnapshot<Category>, unique: UniqueEngine) {
        self.init(
            category: snapshot.association,
            amount: snapshot.amount.rawValue,
            period: snapshot.period,
            parent: nil,
        )
    }
    
    public func makeSnapshot() -> BudgetGoalSnapshot<Category> {
        return .init(self)
    }
    public static func makeBlankSnapshot() -> BudgetGoalSnapshot<Category> {
        return .init()
    }
    public func update(_ from: BudgetGoalSnapshot<Category>, unique: UniqueEngine) {
        self.association = from.association
        self.amount = amount
    }
}
extension BudgetSpendingGoal : BudgetGoal {
    public func duplicate() -> BudgetSpendingGoal {
        .init(category: self.association, amount: self.amount, period: self.period, parent: nil)
    }
}
