//
//  BudgetMonth.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import CoreData
import Observation

extension Budget {
    public var date: MonthYear {
        .init(Int(self.year), Int(self.month))
    }
    public var start: Date? {
        Calendar.current.date(from: .init(year: Int(self.year), month: Int(self.month), day: 1))
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
    
    public var title: String {
        if let result = internalTitle, internalTitleHash == date.hashValue {
            return result
        }
        else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy") // Full month name
            
            let result: String;
            if let date = Calendar.current.date(from: DateComponents(year: date.year, month: date.month)) {
                result = formatter.string(from: date)
                internalTitle = result
                internalTitleHash = Int32(date.hashValue)
            }
            else {
                result = NSLocalizedString("internalError", comment: "")
                internalTitle = nil
                internalTitleHash = 0
            }
            
            return result
        }
    }
    
    public var spendingGoals: [BudgetSpendingGoal] {
        get {
            guard let raw = self.savings, let set = raw as? Set<BudgetSpendingGoal> else {
                return Array();
            }
            
            return Array(set)
        }
        set {
            self.savings = Set(newValue) as NSSet
        }
    }
    public var savingsGoals: [BudgetSavingsGoal] {
        get {
            guard let raw = self.savings, let set = raw as? Set<BudgetSavingsGoal> else {
                return Array();
            }
            
            return Array(set)
        }
        set {
            self.savings = Set(newValue) as NSSet
        }
    }
    
    
    public static func blankBudgetMonth(forDate: MonthYear, cx: NSManagedObjectContext) -> Budget {
        let budget = Budget(context: cx);
        budget.year = Int32(forDate.year)
        budget.month = Int16(forDate.month)
        
        return budget;
    }
    public static func examples(cat: inout ElementLocator<Category>, acc: inout AccountLocator, cx: NSManagedObjectContext) -> Budget {
        let date = MonthYear.now!;
        let result = BudgetMonth(date: date)
        
        let personal = cat.getOrInsert(name: "Personal")
        let groceries = cat.getOrInsert(name: "Groceries")
        let car = cat.getOrInsert(name: "Car")
        
        let checking = acc.getOrInsert(name: "Checking")
        let savings = acc.getOrInsert(name: "Savings")
        
        result.income = [
            .init(name: "Paycheck 1", amount: 560.75, kind: .pay),
            .init(name: "Paycheck 2", amount: 612.15, kind: .pay)
        ]
        result.spendingGoals = [
            .init(category: personal, amount: 100, period: .biWeekly),
            .init(category: groceries, amount: 400, period: .monthly),
            .init(category: car, amount: 120, period: .monthly)
        ]
        result.savingsGoals = [
            .init(account: savings, amount: 400, period: .biWeekly),
            .init(account: checking, amount: 100, period: .monthly)
        ]
        
        return result
    }
}

extension BudgetMonth : SnapshotableElement {
    
    
    
    
    public func dupliate(date: MonthYear) -> BudgetMonth {
        .init(
            date: date,
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
        self.income = try! await incomeUpdater.joinByLength(update: { element, snap, _ in
            element.updateShallow(snap)
        }, create: { snap, _ in
            IncomeDivision(snap)
        })
    }
    
}

@Observable
public class BudgetMonthSnapshot : ElementSnapshot {
    public init() {
        self.dates = nil;
        self.savingsGoals = []
        self.spendingGoals = []
        self.income = []
        self.title = "New Budget"
    }
    public init(_ data: BudgetMonth) {
        self.dates = (data.start ?? .distantPast, data.end ?? .distantFuture);
        self.savingsGoals = data.savingsGoals.map { $0.makeSnapshot() }
        self.spendingGoals = data.spendingGoals.map { $0.makeSnapshot() }
        self.income = data.income.map { $0.makeSnapshot() }
        self.title = data.title
    }
    
    @ObservationIgnored private var dates: (Date, Date)?;
    @ObservationIgnored public let title: String;
    
    public var spendingGoals: [BudgetSpendingGoalSnapshot];
    public var savingsGoals: [BudgetSavingsGoalSnapshot];
    public var income: [ShallowIncomeDivisionSnapshot];
    
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
