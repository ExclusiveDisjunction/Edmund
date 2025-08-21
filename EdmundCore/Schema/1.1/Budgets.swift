//
//  Budgets.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    @Model
    public final class BudgetIncome : Identifiable {
        public init(name: String, amount: Decimal, date: Date?, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.name = name
            self.id = id
            self.amount = amount
            self.date = date
        }
        public init(migrate: EdmundModelsV1.BudgetIncome) {
            self.name = migrate.name
            self.id = migrate.id
            self.amount = migrate.amount
            self.date = date
        }
        
        
        public var id: UUID;
        public var name: String;
        public var amount: Decimal;
        public var date: Date?;
        @Relationship
        public var parent: BudgetMonth?;
    }
    
    @Model
    public final class BudgetSavingsGoal : Identifiable {
        public init(account: SubAccount?, amount: Decimal, period: MonthlyTimePeriods, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = account
            self.amount = amount
            self.parent = parent
            self._period = period.rawValue
        }
        public init(migrate: EdmundModelsV1.BudgetSavingsGoal, association: SubAccount?) {
            self.id = migrate.id
            self.association = association
            self.amount = migrate.amount
            self.parent = nil
            self._period = MonthlyTimePeriods.monthly.rawValue
        }
        
        
        public var id: UUID;
        public var amount: Decimal;
        public internal(set) var _period: MonthlyTimePeriods.RawValue;
        
        @Relationship
        public var association: SubAccount?;
        @Relationship
        public var parent: BudgetMonth?;
    }
    
    @Model
    public final class BudgetSpendingGoal : Identifiable {
        public init(category: SubCategory?, amount: Decimal, period: MonthlyTimePeriods, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.id = id
            self.association = category
            self.amount = amount
            self._period = period.rawValue
            self.parent = parent
        }
        public init(migrate: EdmundModelsV1.BudgetSpendingGoal, association: SubCategory?) {
            self.id = migrate.id
            self.association = association
            self.amount = migrate.amount
            self.parent = nil
            self._period = MonthlyTimePeriods.monthly.rawValue
        }
        
        
        public var id: UUID;
        public var amount: Decimal;
        public internal(set) var _period: MonthlyTimePeriods.RawValue;
        
        @Relationship
        public var association: SubCategory?;
        @Relationship
        public var parent: BudgetMonth?;
    }
    
    @Model
    public class BudgetMonth : Identifiable {
        public init(date: MonthYear, spendingGoals: [BudgetSpendingGoal] = [], savingsGoals: [BudgetSavingsGoal] = [], income: [BudgetIncome] = [], id: UUID = UUID()) {
            self.date = date
            self.spendingGoals = spendingGoals
            self.savingsGoals = savingsGoals
            self.income = income
            self.id = id
        }
        
        public var id: UUID;
        public internal(set) var date: MonthYear;
        
        @Relationship(deleteRule: .cascade, inverse: \BudgetSpendingGoal.parent)
        public var spendingGoals: [BudgetSpendingGoal];
        @Relationship(deleteRule: .cascade, inverse: \BudgetSavingsGoal.parent)
        public var savingsGoals: [BudgetSavingsGoal];
        @Relationship(deleteRule: .cascade, inverse: \BudgetIncome.parent)
        public var income: [BudgetIncome];
        
        @Transient
        public internal(set) var _title: String? = nil;
        @Transient
        public internal(set) var _titleHash: Int = 0;
    }
}
