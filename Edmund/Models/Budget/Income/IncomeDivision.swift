//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import Foundation
import CoreData

extension IncomeDivision {
    public var name: String {
        get { self.internalName ?? "" }
        set { self.internalName = newValue }
    }
    public var kind: IncomeKind {
        get { IncomeKind(rawValue: self.internalKind) ?? .pay }
        set { self.internalKind = newValue.rawValue }
    }
    public var amount: Decimal {
        get { self.internalAmount as Decimal? ?? 0.0 }
        set { self.internalAmount = newValue as NSDecimalNumber }
    }
    
    public var devotions: [IncomeDevotion] {
        get {
            guard let raw = self.internalDevotions, let set = raw as? Set<IncomeDevotion> else {
                return Array();
            }
            
            return Array(set)
        }
        set {
            self.internalDevotions = Set(newValue) as NSSet;
        }
    }
    
    ///The total amount of money taken up by `amounts` and `percents`.
    public var devotionsTotal: Decimal {
        self.devotions.reduce(0.0) { old, devotion in
            if let amount = devotion as? AmountDevotion {
                old + amount.amount
            }
            else if let percent = devotion as? PercentDevotion {
                old + percent.percent * self.amount
            }
            else {
                old
            }
        }
    }
    public var remainderValue: Decimal {
        return self.amount - devotionsTotal
    }
    public var perRemainderValue: Decimal {
        // This implementation is slightly redundant, however,
        // it is this way to redue the number of times the devotions
        // property is created.
        // This is equivalent to (remainderValue / Countof(RemainderDevotion))
        
        var total = Decimal();
        var count = Int(); //Remainders
        
        for devotion in self.devotions {
            if let  _ = devotion as? RemainderDevotion {
                count += 1;
            }
            else if let amount = devotion as? AmountDevotion {
                total += amount.amount;
            }
            else if let percent = devotion as? PercentDevotion {
                total += percent.percent * self.amount
            }
        }
        
        let allRemainders = self.amount - total;
        return allRemainders / Decimal(count)
    }
    public var variance: Decimal {
        let hasRemainder = self.internalDevotions?.first(where: { $0 as? RemainderDevotion != nil } ) != nil;
        
        if hasRemainder {
            return Decimal()
        }
        else {
            return self.remainderValue
        }
    }
    
    
    /*
    public func updateShallow(_ snap: ShallowIncomeDivisionSnapshot) {
        if self.isFinalized {
            return; //Do not update if it is finalized
        }
        
        let name = snap.name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = name
        self.amount = snap.amount.rawValue
        self.kind = snap.kind
        self.depositTo = snap.depositTo
        self.lastUpdated = .now
    }
    public func update(_ snap: IncomeDivisionSnapshot, unique: UniqueEngine) async {
        self.updateShallow(snap)
        
        let updater = ChildUpdater(source: self.devotions, snapshots: snap.devotions, context: modelContext, unique: unique);
        self.devotions = try! await updater.mergeById()
    }
    
    public static func exampleDivision(acc: inout ElementLocator<Account>) -> IncomeDivision {
        let checking = acc.getOrInsert(name: "Checking")
        let savings  = acc.getOrInsert(name: "Savings")
        
        let result = IncomeDivision(name: "Example Division", amount: 450, kind: .pay, depositTo: checking)
        
        result.devotions = [
            .init(name: "Bills", amount: .amount(137.50), account: checking, group: .need),
            .init(name: "Groceries", amount: .amount(137.50), account: checking, group: .need),
            .init(name: "Personal", amount: .amount(137.50), account: checking, group: .want),
            
            .init(name: "Taxes", amount: .percent(0.08), account: savings, group: .savings),
            
            .init(name: "Savings", amount: .remainder, account: savings, group: .savings)
        ]
        
        return result
    }
     */
}
