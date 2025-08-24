//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import Foundation
import SwiftData

public enum IncomeDivisionSortField : CaseIterable, Identifiable {
    case name
    case amount
    case lastUpdated
    case lastViewed
    
    public var id: Self { self }
    
    public func sorted(data: [IncomeDivision], asc: Bool) -> [IncomeDivision] {
        let order: SortOrder = asc ? .forward : .reverse
        
        switch self {
            case .amount:      return data.sorted(using: KeyPathComparator(\.amount,      order: order))
            case .name:        return data.sorted(using: KeyPathComparator(\.name,        order: order))
            case .lastViewed:  return data.sorted(using: KeyPathComparator(\.lastViewed,  order: order))
            case .lastUpdated: return data.sorted(using: KeyPathComparator(\.lastUpdated, order: order))
        }
    }
}
public enum IncomeDivisionFilterField : CaseIterable, Identifiable {
    case finalized
    case notFinalized
    
    public var id: Self { self }
}

extension IncomeDivision : SnapshotableElement, DefaultableElement {
    public typealias SortType = IncomeDivisionSortField
    public typealias FilterType = IncomeDivisionFilterField
    public typealias Snapshot = IncomeDivisionSnapshot;
    
    public convenience init() {
        self.init(name: "", amount: 0, kind: .pay)
    }
    public convenience init(_ from: ShallowIncomeDivisionSnapshot) {
        self.init()
        self.updateShallow(from)
    }
    
    public var kind: IncomeKind {
        get {
            IncomeKind(rawValue: _kind) ?? .pay
        }
        set {
            _kind = newValue.rawValue
        }
    }
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
    public func makeShallowSnapshot() -> ShallowIncomeDivisionSnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> IncomeDivisionSnapshot {
        .init()
    }
    public static func makeBlankShallowSnapshot() -> ShallowIncomeDivisionSnapshot {
        .init()
    }
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
        
        let amountsUpdater = ChildUpdater(source: amounts, snapshots: newAmounts, context: modelContext, unique: unique)
        let percentsUpdater = ChildUpdater(source: percents, snapshots: newPercents, context: modelContext, unique: unique)
        
        self.amounts = try! await amountsUpdater.mergeById()
        self.percents = try! await percentsUpdater.mergeById()
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
    
    public static func exampleDivision(acc: inout ElementLocator<Account>) -> IncomeDivision {
        let checking = acc.getOrInsert(name: "Checking")
        let savings  = acc.getOrInsert(name: "Savings")
        
        let result = IncomeDivision(name: "Example Division", amount: 450, kind: .pay, depositTo: checking)
        
        result.amounts = [
            .init(name: "Bills", amount: 137.50, account: checking, group: .need),
            .init(name: "Groceries", amount: 100, account: checking, group: .need),
            .init(name: "Personal", amount: 30, account: checking, group: .want)
        ]
        result.percents = [
            .init(name: "Taxes", amount: 0.08, account: savings, group: .savings)
        ]
        result.remainder = .init(name: "Savings", account: savings, group: .savings)
        
        return result
    }
    
    @MainActor
    public static func getExample() throws -> IncomeDivision {
        let container = try Containers.debugContainer();
        let item = (try container.context.fetch(FetchDescriptor<IncomeDivision>())).first!
        
        return item;
    }
}

@Observable
public class ShallowIncomeDivisionSnapshot : Identifiable, Hashable, Equatable, ElementSnapshot {
    public init() {
        self.id = UUID();
        self.name = ""
        self.amount = .init()
        self.kind = .pay
        self.depositTo = nil;
        self.isFinalized = false;
    }
    public init(_ from: IncomeDivision) {
        self.id = from.id;
        self.name = from.name
        self.amount = .init(rawValue: from.amount)
        self.kind = from.kind
        self.depositTo = from.depositTo
        self.isFinalized = from.isFinalized
    }
    
    @ObservationIgnored public let id: UUID;
    @ObservationIgnored public let isFinalized: Bool;
    public var name: String;
    public var amount: CurrencyValue;
    public var kind: IncomeKind;
    public var depositTo: Account?;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty && depositTo != nil else {
            return .empty
        }
        
        guard amount.rawValue >= 0 else {
            return .negativeAmount
        }
        
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(amount)
        hasher.combine(kind)
        hasher.combine(depositTo)
    }
    public static func ==(lhs: ShallowIncomeDivisionSnapshot, rhs: ShallowIncomeDivisionSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.amount == rhs.amount && lhs.kind == rhs.kind && lhs.depositTo == rhs.depositTo
    }
}

@Observable
public final class IncomeDivisionSnapshot : ShallowIncomeDivisionSnapshot {
    public override init() {
        self.devotions = []
        self.hasRemainder = true
        self.remainder = .init()
        
        super.init()
    }
    public override init(_ from: IncomeDivision) {
        self.devotions = from.amounts.map { .amount($0.makeSnapshot()) } + from.percents.map { .percent($0.makeSnapshot()) }
        if let remainder = from.remainder {
            self.remainder = .init(remainder)
            self.hasRemainder = true
        }
        else {
            self.remainder = .init()
            self.hasRemainder = false
        }
        
        super.init(from)
    }
    
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
    
    public override func validate(unique: UniqueEngine) -> ValidationFailure? {
        if let result = super.validate(unique: unique) {
            return result
        }
        
        if hasRemainder {
            if let failure = remainder.validate(unique: unique) {
                return failure
            }
        }
        
        for devotion in devotions {
            if let failure = devotion.validate(unique: unique) {
                return failure
            }
        }
        
        return nil
    }
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
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
