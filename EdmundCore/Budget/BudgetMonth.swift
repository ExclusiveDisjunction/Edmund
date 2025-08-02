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
            let calendar = Calendar.current;
            
            guard let currentFirstDay = self.start,
                  let followingFirstDay = calendar.date(byAdding: .month, value: 1, to: currentFirstDay),
                  let currentLastDay = calendar.date(byAdding: .day, value: -1, to: followingFirstDay) else {
                      return nil
                  }
            
            return currentLastDay
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
                formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy") // Full month name
                
                let result: String;
                if let date = Calendar.current.date(from: DateComponents(year: date.year, month: date.month)) {
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
        public static func blankBudgetMonth(forDate: MonthYear) -> BudgetMonth {
            return BudgetMonth(date: forDate)
        }
        @MainActor
        public static func exampleBudgetMonth(cat: inout BoundPairTree<Category>, acc: inout BoundPairTree<Account>) -> BudgetMonth {
            let result = BudgetMonth(date: .init(2025, 7))
            
            result.income = [
                .init(name: "Paycheck 1", amount: 560.75, date: Date.fromParts(2025, 7, 10)),
                .init(name: "Paycheck 2", amount: 612.15, date: Date.fromParts(2025, 7, 25))
            ]
            result.spendingGoals = [
                .init(category: cat.getOrInsert(parent: "Personal", child: "Dining"), amount: 100),
                .init(category: cat.getOrInsert(parent: "Home", child: "Groceries"), amount: 250),
                .init(category: cat.getOrInsert(parent: "Car", child: "Gas"), amount: 120)
            ]
            result.savingsGoals = [
                .init(account: acc.getOrInsert(parent: "Savings", child: "Main"), amount: 400),
                .init(account: acc.getOrInsert(parent: "Checking", child: "Taxes"), amount: 100)
            ]
            
            return result
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
