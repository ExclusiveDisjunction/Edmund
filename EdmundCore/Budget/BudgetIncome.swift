//
//  BudgetIncome.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import SwiftData
import Observation

extension EdmundModelsV1 {
    @Model
    public class BudgetIncome : Identifiable, SnapshotableElement {
        public init(name: String, amount: Decimal, date: Date?, parent: BudgetMonth? = nil, id: UUID = UUID()) {
            self.name = name
            self.id = id
            self.amount = amount
            self.date = date
        }
        
        public var id: UUID;
        public var name: String;
        public var amount: Decimal;
        public var date: Date?;
        @Relationship
        public var parent: BudgetMonth?;
        
        public func duplicate() -> BudgetIncome {
            .init(name: self.name, amount: self.amount, date: self.date, parent: nil)
        }
        
        public func makeSnapshot() -> BudgetIncomeSnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> BudgetIncomeSnapshot {
            .init()
        }
        public func update(_ from: BudgetIncomeSnapshot, unique: UniqueEngine) {
            self.name = from.name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.amount = from.amount.rawValue
            self.date = from.hasDate ? from.date : nil
        }
    }
}

public typealias BudgetIncome = EdmundModelsV1.BudgetIncome;

@Observable
public class BudgetIncomeSnapshot : ElementSnapshot {
    public init() {
        self.name = ""
        self.amount = .init()
        self.date = .now;
        self.hasDate = false;
    }
    public init(_ data: BudgetIncome) {
        self.name = data.name
        self.amount = .init(rawValue: data.amount)
        if let date = data.date {
            self.hasDate = true
            self.date = date
        }
        else {
            self.hasDate = false
            self.date = .now
        }
    }
    
    public var name: String;
    public var amount: CurrencyValue;
    public var hasDate: Bool;
    public var date: Date;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return .empty
        }
        
        if amount < 0 {
            return .negativeAmount
        }
        
        return nil;
    }
    public func dateInRange(start: Date, end: Date) -> Bool {
        return hasDate ? (date >= start && date <= end) : true;
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(amount)
        hasher.combine(hasDate)
        hasher.combine(date)
    }
    public static func ==(lhs: BudgetIncomeSnapshot, rhs: BudgetIncomeSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.amount == rhs.amount && (lhs.hasDate ? lhs.date : nil) == (rhs.hasDate ? rhs.date : nil)
    }
}
