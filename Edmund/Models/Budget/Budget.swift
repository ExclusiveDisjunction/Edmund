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
    
    public var income: [IncomeDivision] {
        get {
            guard let raw = self.divisions, let set = raw as? Set<IncomeDivision> else {
                return Array()
            }
            
            return Array(set)
        }
        set {
            self.divisions = Set(newValue) as NSSet;
        }
    }
    public var spendingGoals: [BudgetSpendingGoal] {
        get {
            guard let raw = self.spending, let set = raw as? Set<BudgetSpendingGoal> else {
                return Array();
            }
            
            return Array(set)
        }
        set {
            self.spending = Set(newValue) as NSSet
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
        let result = Budget.blankBudgetMonth(forDate: MonthYear.now!, cx: cx)
        
        let personal = cat.getOrInsert(name: "Personal", cx: cx)
        let groceries = cat.getOrInsert(name: "Groceries", cx: cx)
        let car = cat.getOrInsert(name: "Car", cx: cx);
        
        let pay = acc.getOrInsertEnvolope(name: "Pay", accountName: "Checking", cx: cx);
        let main = acc.getOrInsertEnvolope(name: "Main", accountName: "Savings", cx: cx);
        let bills = acc.getOrInsertEnvolope(name: "Bills", accountName: "Checking", cx: cx);

        do {
            let paychecks = [IncomeDivision(context: cx), IncomeDivision(context: cx)];
            
            /*
             result.income = [
                 .init(name: "Paycheck 1", amount: 560.75, kind: .pay),
                 .init(name: "Paycheck 2", amount: 612.15, kind: .pay)
             ]
             */
            
            result.income = paychecks;
        }
        do {
            let spendingGoals = [BudgetSpendingGoal(context: cx), BudgetSpendingGoal(context: cx), BudgetSpendingGoal(context: cx)];
            
            spendingGoals[0].amount = 100;
            spendingGoals[0].period = .biWeekly;
            spendingGoals[0].association = personal;
            
            spendingGoals[1].amount = 400;
            spendingGoals[1].period = .monthly;
            spendingGoals[1].association = groceries;
            
            spendingGoals[2].amount = 120;
            spendingGoals[2].period = .monthly;
            spendingGoals[2].association = car;
            
            result.spendingGoals = spendingGoals;
        }
        do {
            let savingsGoals = [BudgetSavingsGoal(context: cx), BudgetSavingsGoal(context: cx)];
            
            savingsGoals[0].amount = 400;
            savingsGoals[0].period = .biWeekly;
            savingsGoals[0].association = main;
            
            savingsGoals[0].amount = 100;
            savingsGoals[0].period = .monthly;
            savingsGoals[0].association = bills;
            
            result.savingsGoals = savingsGoals
        }
            
        return result
    }
}

/*
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
 */
