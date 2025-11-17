//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import Foundation
import SwiftData
import SwiftUI

public enum IncomeDivisionSortField : Sortable, CaseIterable, Identifiable {
    case name
    case amount
    case lastUpdated
    case lastViewed
    
    public var id: Self { self }
}
public enum IncomeDivisionFilterField : Filterable, CaseIterable, Identifiable {
    case finalized
    case notFinalized
    
    public var id: Self { self }
}

extension IncomeDivision : DefaultableElement {
    public convenience init() {
        self.init(name: "", amount: 0, kind: .pay)
    }
}
extension IncomeDivision : Queryable {
    public static func sort(_ data: [IncomeDivision], using: IncomeDivisionSortField, order: SortOrder) -> [IncomeDivision] {
        switch using {
            case .amount:      return data.sorted(using: KeyPathComparator(\.amount,      order: order))
            case .name:        return data.sorted(using: KeyPathComparator(\.name,        order: order))
            case .lastViewed:  return data.sorted(using: KeyPathComparator(\.lastViewed,  order: order))
            case .lastUpdated: return data.sorted(using: KeyPathComparator(\.lastUpdated, order: order))
        }
    }
    
    public static func filter(_ data: [IncomeDivision], using: Set<IncomeDivisionFilterField>) -> [IncomeDivision] {
        data.filter {
            (using.contains(.finalized) && $0.isFinalized) || (using.contains(.notFinalized) && !$0.isFinalized)
        }
    }
    
    public typealias SortType = IncomeDivisionSortField
    public typealias FilterType = IncomeDivisionFilterField
}
extension IncomeDivision : SnapshotableElement {
    public typealias Snapshot = IncomeDivisionSnapshot;

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
        
        let amountsUpdater = ChildUpdater(source: self.devotions, snapshots: snap.devotions, context: modelContext, unique: unique)
        
        self.devotions = try! await amountsUpdater.mergeById()
    }
}
extension IncomeDivision : InspectableElement {
    public typealias InspectView = IncomeDivisionInspect;
    
    @MainActor
    public func makeInspectView() -> some View {
        IncomeDivisionInspect(data: self)
    }
}
extension IncomeDivision : EditableElement {
    public typealias EditView = IncomeDivisionEdit
    
    @MainActor
    public static func makeEditView(_ snap: Snapshot) -> IncomeDivisionEdit {
        IncomeDivisionEdit(snap)
    }
}
public extension IncomeDivision {
    convenience init(_ from: ShallowIncomeDivisionSnapshot) {
        self.init()
        self.updateShallow(from)
    }
    
    /*
     - There can be more than one remainder.
     - Each remainder will take a part of the total for remainders
     - The total will look at the hash of the devotions list for speeding up.
     */
    
    var devotionsTotal: Decimal {
        get {
            let newHash = devotions.hashValue;
            guard newHash != self._devotionsHash else {
                return self._devotionsTotal
            }
            
            var total: Decimal;
            for devotion in self.devotions {
                switch devotion.kind {
                    case .amount(let a): total += a
                    case .percent(let p): total += self.amount * p
                    case .remainder: ()
                }
            }
            self._devotionsTotal = total;
            self._devotionsHash = newHash;
            
            return total;
        }
    }
    var remaindersCount: Int {
        get {
            let newHash = devotions.hashValue;
            guard newHash != self._devotionsHash else {
                return _remaindersCount;
            }
            
            let count = self.devotions.count(where: { $0.kind == .remainder } )
            
            self._remaindersCount = count;
            self._devotionsHash = newHash;
            
            return count;
        }
    }
    var remainderTotal: Decimal {
        return self.amount - devotionsTotal
    }
    var perRemainderAmount: Decimal {
        return remainderTotal / Decimal(remaindersCount)
    }
    var moneyLeft: Decimal {
        if remainderTotal != 0 {
            return 0;
        }
        else {
            return self.amount - remainderTotal
        }
    }
    
    func duplicate() -> IncomeDivision {
        IncomeDivision(
            name: self.name,
            amount: self.amount,
            kind: self.kind,
            depositTo: self.depositTo,
            lastViewed: .now,
            lastUpdated: .now,
            devotions: self.devotions.map { $0.duplicate() }
        )
    }
    
    static func queryPredicate(_ criteria: String) -> Predicate<IncomeDivision> {
        let tryDate = try? Date(criteria, strategy: .dateTime);
        let amount = Decimal.init(floatLiteral: Double(criteria) ?? 0);
        
        return #Predicate<IncomeDivision> { item in
            item.name.caseInsensitiveCompare(criteria) == ComparisonResult.orderedSame ||
            item.amount == amount
        }
    }
    func query(_ criteria: String) -> Bool {
        // Assume the critera is lowercase
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return name.lowercased().contains(criteria) ||
        String(describing: amount).lowercased().contains(criteria) ||
        formatter.string(from: lastUpdated).lowercased().contains(criteria) ||
        formatter.string(from: lastViewed).lowercased().contains(criteria)
    }
    
    static func exampleDivision(acc: inout ElementLocator<Account>) -> IncomeDivision {
        let checking = acc.getOrInsert(name: "Checking")
        let savings  = acc.getOrInsert(name: "Savings")
        
        let result = IncomeDivision(name: "Example Division", amount: 450, kind: .pay, depositTo: checking)
        
        result.devotions = [
            .init(name: "Bills", kind: .amount(137.50), account: checking, group: .need),
            .init(name: "Groceries", kind: .amount(100), account: checking, group: .need),
            .init(name: "Personal", kind: .amount(30), account: checking, group: .want),
            .init(name: "Taxes", kind: .percent(0.08), account: savings, group: .savings),
            .init(name: "Savings", kind: .remainder, account: savings, group: .savings)
        ];
        
        
        return result
    }
}

extension DevotionGroup : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
            default: "internalError"
        }
    }
}
extension IncomeKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .pay: "Pay"
            case .gift: "Gift"
            case .donation: "Donation"
            default: "internalError"
        }
    }
}
extension MonthlyTimePeriods : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .weekly: "Weekly"
            case .biWeekly: "Bi-Weekly"
            case .monthly: "Monthly"
            default: "internalError"
        }
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
        self.devotions = from.devotions.map { IncomeDevotionSnapshot(from: $0) }
        
        super.init(from)
    }
    
    public var devotions: [IncomeDevotionSnapshot];
    
    @ObservationIgnored
    fileprivate var _devotionsHash: Int = 0;
    @ObservationIgnored
    fileprivate var _devotionsTotal: Decimal = 0;
    @ObservationIgnored
    fileprivate var _remaindersCount: Int = 0;
    
    public var devotionsTotal: Decimal {
        get {
            let newHash = devotions.hashValue;
            guard newHash != self._devotionsHash else {
                return self._devotionsTotal
            }
            
            var total: Decimal;
            for devotion in self.devotions {
                switch devotion.kind {
                    case .amount(let a): total += a.rawValue
                    case .percent(let p): total += self.amount.rawValue * p.rawValue
                    case .remainder: ()
                }
            }
            self._devotionsTotal = total;
            self._devotionsHash = newHash;
            
            return total;
        }
    }
    public var remaindersCount: Int {
        get {
            let newHash = devotions.hashValue;
            guard newHash != self._devotionsHash else {
                return _remaindersCount;
            }
            
            let count = self.devotions.count(where: { $0.kind == .remainder } )
            
            self._remaindersCount = count;
            self._devotionsHash = newHash;
            
            return count;
        }
    }
    public var remainderTotal: Decimal {
        return self.amount.rawValue - devotionsTotal
    }
    public var perRemainderAmount: Decimal {
        return remainderTotal / Decimal(remaindersCount)
    }
    public var moneyLeft: Decimal {
        if remainderTotal != 0 {
            return 0;
        }
        else {
            return self.amount.rawValue - remainderTotal
        }
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
