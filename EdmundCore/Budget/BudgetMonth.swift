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
        public init(date: MonthYear, spendingGoals: [BudgetSpendingGoal] = [], savingsGoals: [BudgetSavingsGoal] = [], income: [BudgetIncome] = [], id: UUID = UUID()) {
            self.date = date
            self.spendingGoals = spendingGoals
            self.savingsGoals = savingsGoals
            self.income = income
            self.id = id
        }
        
        public var id: UUID;
        public private(set) var date: MonthYear;
        public var start: Date? {
            Calendar.current.date(from: .init(year: date.year, month: date.month, day: 1))
        }
        public var end: Date? {
            Calendar.current.date(from: .init(year: date.year, month: date.month, day: 0))
        }
        @Relationship(deleteRule: .cascade, inverse: \BudgetSpendingGoal.parent)
        public var spendingGoals: [BudgetSpendingGoal];
        @Relationship(deleteRule: .cascade, inverse: \BudgetSavingsGoal.parent)
        public var savingsGoals: [BudgetSavingsGoal];
        @Relationship(deleteRule: .cascade, inverse: \BudgetIncome.parent)
        public var income: [BudgetIncome];
        
        @Transient
        private var _title: String? = nil;
        @Transient
        private var _titleHash: Int = 0;
        public var title: String {
            if let result = _title, _titleHash == date.hashValue {
                return result
            }
            else {
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.setLocalizedDateFormatFromTemplate("MMMM") // Full month name
                
                let result: String;
                if let date = Calendar.current.date(from: DateComponents(month: date.month)) {
                    result = formatter.string(from: date)
                    _title = result
                    _titleHash = date.hashValue
                }
                else {
                    result = NSLocalizedString("internalError", comment: "")
                    _title = nil
                    _titleHash = 0
                }
                
                return result
            }
        }
        
        public func dupliate() -> BudgetMonth {
            .init(
                date: self.date,
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
        
        @MainActor
        public func blankBudgetMonth(forDate: MonthYear) -> BudgetMonth {
            return BudgetMonth(date: forDate)
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
        self.dates = (data.start ?? .distantPast, data.end ?? .distantFuture);
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
