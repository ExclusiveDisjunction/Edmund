//
//  BudgetMonth.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import SwiftData
import Observation

extension EdmundModelsV1 {
    @Model
    public class BudgetMonth : Identifiable, SnapshotableElement {
        public init(start: Date, end: Date, spendingGoals: [BudgetSpendingGoal] = [], savingsGoals: [BudgetSavingsGoal] = [], income: [BudgetIncome] = [], id: UUID = UUID()) {
            self.start = start
            self.end = end
            self.spendingGoals = spendingGoals
            self.savingsGoals = savingsGoals
            self.income = income
            self.id = id
        }
        
        public var id: UUID;
        public var start: Date;
        public var end: Date;
        @Relationship(deleteRule: .cascade, inverse: \BudgetSpendingGoal.parent)
        public var spendingGoals: [BudgetSpendingGoal];
        @Relationship(deleteRule: .cascade, inverse: \BudgetSavingsGoal.parent)
        public var savingsGoals: [BudgetSavingsGoal];
        @Relationship(deleteRule: .cascade, inverse: \BudgetIncome.parent)
        public var income: [BudgetIncome];
        
        public func dupliate() -> BudgetMonth {
            .init(
                start: self.start,
                end: self.end,
                spendingGoals: self.spendingGoals.map { $0.duplicate() },
                savingsGoals: self.savingsGoals.map { $0.duplicate() },
                income: self.income.map { $0.duplicate() }
            )
        }
        
        public func makeSnapshot() -> BudgetMonthSnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetMonthSnapshot {
            .init()
        }
        public func update(_ from: BudgetMonthSnapshot, unique: UniqueEngine) async {
            let incomeUpdater = ChildUpdater(source: income, snapshots: from.income, context: modelContext, unique: unique);
            let savingsUpdater = ChildUpdater(source: savingsGoals, snapshots: from.savingsGoals, context: modelContext, unique: unique);
            let spendingUpdater = ChildUpdater(source: spendingGoals, snapshots: from.spendingGoals, context: modelContext, unique: unique);
            
            self.spendingGoals = try! await spendingUpdater.joinByLength()
            self.savingsGoals = try! await savingsUpdater.joinByLength()
            self.income = try! await incomeUpdater.joinByLength()
        }
    }
}

public typealias BudgetMonth = EdmundModelsV1.BudgetMonth;

@Observable
public class BudgetMonthSnapshot : ElementSnapshot {
    public init() {
        self.dates = nil;
        self.savingsGoals = []
        self.spendingGoals = []
        self.income = []
    }
    public init(_ data: BudgetMonth) {
        self.dates = (data.start, data.end);
        self.savingsGoals = data.savingsGoals.map { $0.makeSnapshot() }
        self.spendingGoals = data.spendingGoals.map { $0.makeSnapshot() }
        self.income = data.income.map { $0.makeSnapshot() }
    }
    
    @ObservationIgnored private var dates: (Date, Date)?;
    
    public var spendingGoals: [BudgetSpendingGoalSnapshot];
    public var savingsGoals: [BudgetSavingsGoalSnapshot];
    public var income: [BudgetIncomeSnapshot];
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        for goal in spendingGoals {
            if let result = goal.validate(unique: unique) {
                return result
            }
        }
        
        for goal in savingsGoals {
            if let result = goal.validate(unique: unique) {
                return result
            }
        }
        
        for item in income {
            if let result = item.validate(unique: unique) {
                return result
            }
            
            if let dates = self.dates, !item.dateInRange(start: dates.0, end: dates.1) {
                return .invalidInput
            }
        }
        
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(spendingGoals)
        hasher.combine(savingsGoals)
        hasher.combine(income)
    }
    public static func ==(lhs: BudgetMonthSnapshot, rhs: BudgetMonthSnapshot) -> Bool {
        lhs.spendingGoals == rhs.spendingGoals && lhs.savingsGoals == rhs.savingsGoals && lhs.income == rhs.income
    }
}
