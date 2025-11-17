//
//  Budgets.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV2 {
    @Model
    public final class BudgetSavingsGoal : Identifiable {
        public init(account: Account?, amount: Decimal, period: MonthlyTimePeriods, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = account
            self.amount = amount
            self.parent = parent
            self.period = period
        }
        
        public var id: UUID = UUID();
        public var amount: Decimal = 0;
        public var period: MonthlyTimePeriods = MonthlyTimePeriods.monthly;
        
        @Relationship
        public var association: Account?;
        @Relationship
        public var parent: BudgetMonth?;
    }
    
    @Model
    public final class BudgetSpendingGoal : Identifiable {
        public init(category: Category?, amount: Decimal, period: MonthlyTimePeriods, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = category
            self.amount = amount
            self.period = period
            self.parent = parent
        }
        
        public var id: UUID = UUID();
        public var amount: Decimal = 0;
        public var period: MonthlyTimePeriods = MonthlyTimePeriods.monthly;
        
        @Relationship
        public var association: Category?;
        @Relationship
        public var parent: BudgetMonth?;
    }
    
    @Model
    public class BudgetMonth : Identifiable {
        public init(date: MonthYear, spendingGoals: [BudgetSpendingGoal] = [], savingsGoals: [BudgetSavingsGoal] = [], income: [IncomeDivision] = [], id: UUID = UUID()) {
            self.date = date
            self.spendingGoals = spendingGoals
            self.savingsGoals = savingsGoals
            self.income = income
            self.id = id
        }
        public init(migrate: EdmundModelsV1.BudgetMonth) {
            self.date = migrate.date
            self.id = UUID();
            self.spendingGoals = [];
            self.savingsGoals = [];
            self.income = [];
        }
        
        public var id: UUID = UUID();
        public internal(set) var date: MonthYear = MonthYear(0, 0)

        @Relationship(deleteRule: .cascade, inverse: \BudgetSpendingGoal.parent)
        public var spendingGoals: [BudgetSpendingGoal] = [];
        @Relationship(deleteRule: .cascade, inverse: \BudgetSavingsGoal.parent)
        public var savingsGoals: [BudgetSavingsGoal] = [];
        @Relationship(deleteRule: .cascade, inverse: \IncomeDivision.parent)
        public var income: [IncomeDivision] = [];
        
        @Transient
        public internal(set) var _title: String? = nil;
        @Transient
        public internal(set) var _titleHash: Int = 0;
    }
}
