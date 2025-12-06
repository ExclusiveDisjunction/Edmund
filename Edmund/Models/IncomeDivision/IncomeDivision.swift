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
        get { IncomeKind(rawValue: _kind) ?? .pay }
        set { _kind = newValue.rawValue }
    }
    ///The total amount of money taken up by `amounts` and `percents`.
    public var devotionsTotal: Decimal {
        self.devotions.reduce(0.0) { old, devotion in
            switch devotion.amount {
                case .amount(let v): old + v
                case .percent(let v): old + (self.amount * v)
                case .remainder: old
            }
        }
    }
    public var remainderValue: Decimal {
        return self.amount - devotionsTotal
    }
    public var variance: Decimal {
        .nan
    }
    
    public func duplicate() -> IncomeDivision {
        IncomeDivision(
            name: self.name,
            amount: self.amount,
            kind: self.kind,
            depositTo: self.depositTo,
            lastViewed: .now,
            lastUpdated: .now,
            devotions: self.devotions.map{ $0.duplicate() },
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
        
        let updater = ChildUpdater(source: self.devotions, snapshots: snap.devotions, context: modelContext, unique: unique);
        self.devotions = try! await updater.mergeById()
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
        
        result.devotions = [
            .init(name: "Bills", amount: .amount(137.50), account: checking, group: .need),
            .init(name: "Groceries", amount: .amount(137.50), account: checking, group: .need),
            .init(name: "Personal", amount: .amount(137.50), account: checking, group: .want),
            
            .init(name: "Taxes", amount: .percent(0.08), account: savings, group: .savings),
            
            .init(name: "Savings", amount: .remainder, account: savings, group: .savings)
        ]
        
        return result
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
        super.init()
    }
    public override init(_ from: IncomeDivision) {
        self.devotions = from.devotions.map { $0.makeSnapshot() }
        
        super.init(from)
    }
    
    public var devotions: [IncomeDevotionSnapshot];
    
    private var moneyLeftDirect: Decimal {
        let raw = amount.rawValue;
        return raw - devotions.reduce(0.0) { old, devotion in
            switch devotion.amount {
                case .amount(let v): old + v.rawValue
                case .percent(let v): old + (raw * v.rawValue)
                case .remainder: old
            }
        }
    }
    public var remainderValue: Decimal {
        .nan
    }
    public var moneyLeft: Decimal {
        .nan
    }
    
    public override func validate(unique: UniqueEngine) -> ValidationFailure? {
        if let result = super.validate(unique: unique) {
            return result
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
    }
    public static func ==(lhs: IncomeDivisionSnapshot, rhs: IncomeDivisionSnapshot) -> Bool {
        (lhs as ShallowIncomeDivisionSnapshot == rhs as ShallowIncomeDivisionSnapshot) && lhs.devotions == rhs.devotions
    }
}
