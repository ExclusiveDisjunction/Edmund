//
//  BudgetSavingsGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/27/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    @Model
    public final class BudgetSavingsGoal : BudgetGoal {
        public init(account: SubAccount?, amount: Decimal, period: MonthlyTimePeriods, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = account
            self.amount = amount
            self.parent = parent
            self._period = period.rawValue
        }
        public convenience init(snapshot: BudgetGoalSnapshot<SubAccount>, unique: UniqueEngine) {
            self.init(
                account: snapshot.association,
                amount: snapshot.amount.rawValue,
                period: snapshot.period,
                parent: nil,
            )
        }
        
        public var id: UUID;
        public var amount: Decimal;
        public private(set) var _period: MonthlyTimePeriods.RawValue;
        public var period: MonthlyTimePeriods {
            get { MonthlyTimePeriods(rawValue: _period) ?? .monthly }
            set { _period = newValue.rawValue }
        }
        @Relationship
        public var association: SubAccount?;
        @Relationship
        public var parent: BudgetMonth?;
        
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
}

public typealias BudgetSavingsGoal = EdmundModelsV1_1.BudgetSavingsGoal
