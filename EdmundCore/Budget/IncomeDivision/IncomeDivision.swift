//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import Foundation
import SwiftData


extension EdmundModelsV1 {
    @Model
    public final class IncomeDivision : Identifiable, SnapshotableElement, DefaultableElement {
        public typealias Snapshot = IncomeDivisionSnapshot;
        
        public convenience init() {
            self.init(name: "", amount: 0, kind: .pay)
        }
        public init(name: String, amount: Decimal, kind: IncomeKind, depositTo: SubAccount? = nil, lastViewed: Date = .now, lastUpdated: Date = .now, amounts: [AmountDevotion] = [], percents: [PercentDevotion] = [], remainder: RemainderDevotion? = nil) {
            self.name = name
            self.amount = amount
            self.depositTo = depositTo
            self._kind = kind.rawValue
            self.lastViewed = lastViewed
            self.lastUpdated = lastUpdated
            self.amounts = amounts
            self.percents = percents
            self.remainder = remainder
            self.id = UUID();
        }
        
        public var id: UUID;
        public var name: String;
        public var amount: Decimal;
        public var isFinalized: Bool = false;
        private var _kind: IncomeKind.RawValue;
        public var kind: IncomeKind {
            get {
                IncomeKind(rawValue: _kind) ?? .pay
            }
            set {
                _kind = newValue.rawValue
            }
        }
        public var lastUpdated: Date;
        public var lastViewed: Date;
        
        @Relationship
        public var depositTo: SubAccount?;
        @Relationship(deleteRule: .cascade, inverse: \AmountDevotion.parent)
        public var amounts: [AmountDevotion];
        @Relationship(deleteRule: .cascade, inverse: \PercentDevotion.parent)
        public var percents: [PercentDevotion];
        @Relationship(deleteRule: .cascade, inverse: \RemainderDevotion.parent)
        public var remainder: RemainderDevotion?;
        
        public var allDevotions: [AnyDevotion] {
            return amounts.map { .amount($0) } + percents.map { .percent($0) } + (remainder != nil ? [.remainder(remainder!)] : [] )
        }
        ///The total amount of money taken up by `amounts` and `percents`.
        public var devotionsTotal: Decimal {
            let setTotal = amounts.reduce(0.0, { $0 + $1.amount } )
            let percentTotal = percents.reduce(0.0, { $0 + $1.amount * self.amount } )
            
            return setTotal + percentTotal
        }
        public var remainderValue: Decimal {
            return self.amount - devotionsTotal
        }
        public var variance: Decimal {
            if self.remainder != nil {
                return 0;
            }
            else {
                return self.amount - remainderValue
            }
        }
        
        public func duplicate() -> IncomeDivision {
            IncomeDivision(
                name: self.name,
                amount: self.amount,
                kind: self.kind,
                depositTo: self.depositTo,
                lastViewed: .now,
                lastUpdated: .now,
                amounts: self.amounts.map { $0.duplicate() },
                percents: self.percents.map { $0.duplicate() },
                remainder: self.remainder?.duplicate()
            )
        }
        
        public func makeSnapshot() -> IncomeDivisionSnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> IncomeDivisionSnapshot {
            .init()
        }
        public func update(_ snap: IncomeDivisionSnapshot, unique: UniqueEngine) async {
            let name = snap.name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.name = name
            self.amount = snap.amount.rawValue
            self.kind = snap.kind
            self.depositTo = snap.depositTo
            self.lastUpdated = .now
            
            if let oldRemainder = self.remainder, snap.hasRemainder {
                oldRemainder.update(snap.remainder, unique: unique)
            }
            else if let oldRemainder = self.remainder, !snap.hasRemainder {
                modelContext?.delete(oldRemainder)
                self.remainder = nil
            }
            else if snap.hasRemainder && self.remainder == nil {
                let new = RemainderDevotion()
                new.update(snap.remainder, unique: unique)
                
                self.remainder = new
                modelContext?.insert(new)
            } // At this point, there is no remainder in the snapshot, and the current remainder is nil, so nothing to do with it.
            
            let newAmounts = snap.devotions.compactMap { if case .amount(let a) = $0 { return a } else { return nil }}
            let newPercents = snap.devotions.compactMap { if case .percent(let a) = $0 { return a } else { return nil }}
            try! await mergeAndUpdateChildren(list: &amounts, merging: newAmounts, context: modelContext, unique: unique) //Amount devotions cannot throw
            try! await mergeAndUpdateChildren(list: &percents, merging: newPercents, context: modelContext, unique: unique)
            
            self.lastUpdated = .now
            
            do {
                try modelContext?.save()
            }
            catch let e {
                print("Notice: Error occured while updating budget instance, error: \(e.localizedDescription)")
            }
        }
        
        public func query(_ criteria: String) -> Bool {
            // Assume the critera is lowercase
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            return name.lowercased().contains(criteria) ||
            String(describing: amount).lowercased().contains(criteria) ||
            formatter.string(from: lastUpdated).lowercased().contains(criteria) ||
            formatter.string(from: lastViewed).lowercased().contains(criteria)
        }
        
        public static func exampleBudget(acc: inout BoundPairTree<Account>) -> IncomeDivision {
            let pay       = acc.getOrInsert(parent: "Checking", child: "Pay"      )
            let bills     = acc.getOrInsert(parent: "Checking", child: "Bills"    )
            let groceries = acc.getOrInsert(parent: "Checking", child: "Groceries")
            let personal  = acc.getOrInsert(parent: "Checking", child: "Personal" )
            let taxes     = acc.getOrInsert(parent: "Checking", child: "Taxes"    )
            let main      = acc.getOrInsert(parent: "Savings",  child: "Main"     )
            
            let result = IncomeDivision(name: "Example Division", amount: 450, kind: .pay, depositTo: pay)
            
            result.amounts = [
                .init(name: "Bills", amount: 137.50, account: bills, group: .need),
                .init(name: "Groceries", amount: 100, account: groceries, group: .need),
                .init(name: "Personal", amount: 30, account: personal, group: .want)
            ]
            result.percents = [
                .init(name: "Taxes", amount: 0.08, account: taxes, group: .savings)
            ]
            result.remainder = .init(name: "Savings", account: main, group: .savings)
            
            return result
        }
        
        @MainActor
        public static func getExampleBudget() throws -> IncomeDivision {
            let container = try Containers.debugContainer();
            let item = (try container.context.fetch(FetchDescriptor<IncomeDivision>())).first!
            
            return item;
        }
    }
}

public typealias IncomeDivision = EdmundModelsV1.IncomeDivision

@Observable
public final class IncomeDivisionSnapshot : Hashable, Equatable, ElementSnapshot {
    public init() {
        self.name = ""
        self.amount = .init()
        self.kind = .pay
        self.depositTo = nil
        self.devotions = []
        self.hasRemainder = true
        self.remainder = .init()
    }
    public init(_ from: IncomeDivision) {
        self.name = from.name;
        self.amount = .init(rawValue: from.amount)
        self.kind = from.kind
        self.depositTo = from.depositTo
        self.devotions = from.amounts.map { .amount(.init($0)) } + from.percents.map { .percent(.init($0)) }
        if let remainder = from.remainder {
            self.remainder = .init(remainder)
            self.hasRemainder = true
        }
        else {
            self.remainder = .init()
            self.hasRemainder = false
        }
    }
    
    public var name: String;
    public var amount: CurrencyValue;
    public var kind: IncomeKind;
    public var depositTo: SubAccount?;
    public var devotions: [AnyDevotionSnapshot];
    public var hasRemainder: Bool;
    public var remainder: DevotionSnapshotBase;
    
    private var moneyLeftDirect: Decimal {
        let raw = amount.rawValue;
        return raw - devotions.reduce(Decimal(), { $0 + $1.amount(raw) } )
    }
    public var remainderValue: Decimal {
        hasRemainder ? moneyLeftDirect : 0
    }
    public var moneyLeft: Decimal {
        hasRemainder ? 0 : moneyLeftDirect
    }
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && depositTo != nil else {
            return .empty
        }
        
        guard amount.rawValue >= 0 else {
            return .negativeAmount
        }
        
        if let failure = remainder.validate(unique: unique) {
            return failure
        }
        
        for devotion in devotions {
            if let failure = devotion.validate(unique: unique) {
                return failure
            }
        }
        
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(amount)
        hasher.combine(kind)
        hasher.combine(depositTo)
        hasher.combine(devotions)
        hasher.combine(hasRemainder)
        hasher.combine(remainder)
    }
    public static func ==(lhs: IncomeDivisionSnapshot, rhs: IncomeDivisionSnapshot) -> Bool {
        let start = lhs.name == rhs.name && lhs.amount == rhs.amount && lhs.kind == rhs.kind && lhs.depositTo == rhs.depositTo && lhs.devotions == rhs.devotions && lhs.hasRemainder == rhs.hasRemainder;
        if lhs.hasRemainder && rhs.hasRemainder {
            return start && lhs.remainder == rhs.remainder
        }
        else {
            return start
        }
    }
}
