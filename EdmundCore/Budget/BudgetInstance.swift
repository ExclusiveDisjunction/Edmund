//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import Foundation
import SwiftData
import SwiftUI

public enum IncomeKind: Int, CaseIterable, Identifiable {
    case pay
    case gift
    case donation
    
    public var id: Self { self }
    public var display: LocalizedStringKey {
        switch self {
            case .pay: "Pay"
            case .gift: "Gift"
            case .donation: "Donation"
        }
    }
}

@Model
public final class BudgetInstance : Identifiable, SnapshotableElement, DefaultableElement {
    public typealias Snapshot = BudgetInstanceSnapshot;
    
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
    public var remainderValue: Decimal {
        let setTotal = amounts.reduce(0.0, { $0 + $1.amount } )
        let percentTotal = percents.reduce(0.0, { $0 + $1.amount * self.amount } )
        
        return self.amount - setTotal - percentTotal
    }
    public var variance: Decimal {
        if self.remainder != nil {
            return 0;
        }
        else {
            return self.amount - remainderValue
        }
    }
    
    public func makeSnapshot() -> BudgetInstanceSnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> BudgetInstanceSnapshot {
        .init()
    }
    public func update(_ snap: BudgetInstanceSnapshot, unique: UniqueEngine) {
        // These types are UUID -> (Devotion, Bool). The bool determines if this value was updated at all from the previous system. If it was not, they will be deleted at the end.
        let oldAmounts = Dictionary(uniqueKeysWithValues: self.amounts.map { ($0.id, ChildUpdateRecord($0)) })
        let oldPercents = Dictionary(uniqueKeysWithValues: self.percents.map { ($0.id, ChildUpdateRecord($0) ) })
        
        // All old & new elements will be added to this list. That way
        var newAmounts: [AmountDevotion] = [];
        var newPercents: [PercentDevotion] = [];
        
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
        
        // Note that try! is ok because these devotions do not throw.
        for devotion in snap.devotions {
            switch devotion {
                case .amount(let amount):
                    try! ChildUpdateRecord.updateOrInsert(amount, old: oldAmounts, modelContext: modelContext, unique: unique, list: &newAmounts)
                case .percent(let percent):
                    try! ChildUpdateRecord.updateOrInsert(percent, old: oldPercents, modelContext: modelContext, unique: unique, list: &newPercents)
            }
        }
        
        // Removes any un-visisted amounts
        let filteredAmounts = oldAmounts.values.filter { !$0.visisted }
        let filteredPercents = oldPercents.values.filter { !$0.visisted }
        
        for amount in filteredAmounts {
            modelContext?.delete(amount.data)
        }
        for percent in filteredPercents {
            modelContext?.delete(percent.data)
        }
        
        // Assign parents to the new & old elements
        for amount in newAmounts {
            amount.parent = self
        }
        for percent in newPercents {
            percent.parent = self
        }
        
        // Assign the correct amounts & percents lists
        self.amounts = newAmounts
        self.percents = newPercents
        
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
    
    public static func exampleBudget(pay: SubAccount, bills: SubAccount, groceries: SubAccount, personal: SubAccount, taxes: SubAccount, main: SubAccount) -> BudgetInstance {
        let result = BudgetInstance(name: "Example Budget", amount: 450, kind: .pay, depositTo: pay)
        
        result.amounts = [
            .init(name: "Bills", amount: 250.56, account: bills, group: .need),
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
    public static func getExampleBudget() -> BudgetInstance {
        let container = Containers.debugContainer;
        let item = (try! container.mainContext.fetch(FetchDescriptor<BudgetInstance>())).first!
        
        return item;
    }
}

extension BudgetInstance : EditableElement, InspectableElement {
    public typealias EditView = BudgetEdit
    public typealias InspectView = BudgetInspect;
    
    public func makeInspectView() -> some View {
        BudgetInspect(data: self)
    }
    public static func makeEditView(_ snap: Snapshot) -> BudgetEdit {
        BudgetEdit(snap)
    }
}

@Observable
public final class BudgetInstanceSnapshot : Hashable, Equatable, ElementSnapshot {
    public init() {
        self.name = ""
        self.amount = .init()
        self.kind = .pay
        self.depositTo = nil
        self.devotions = []
        self.hasRemainder = true
        self.remainder = .init()
    }
    public init(_ from: BudgetInstance) {
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
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        fatalError()
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
    public static func ==(lhs: BudgetInstanceSnapshot, rhs: BudgetInstanceSnapshot) -> Bool {
        let start = lhs.name == rhs.name && lhs.amount == rhs.amount && lhs.kind == rhs.kind && lhs.depositTo == rhs.depositTo && lhs.devotions == rhs.devotions && lhs.hasRemainder == rhs.hasRemainder;
        if lhs.hasRemainder && rhs.hasRemainder {
            return start && lhs.remainder == rhs.remainder
        }
        else {
            return start
        }
    }
    
}

public enum DevotionGroup : Int, Identifiable, CaseIterable {
    case need
    case want
    case savings
    
    public var display: LocalizedStringKey {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
        }
    }
    public var asString: String {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
        }
    }
    
    public var id: Self { self }
}

public protocol DevotionBase : AnyObject, Identifiable<UUID>, SnapshotableElement, DefaultableElement  {
    var name: String { get set }
    var account: SubAccount? { get set }
    var group: DevotionGroup { get set }
}
public enum AnyDevotion : Identifiable {
    case amount(AmountDevotion)
    case percent(PercentDevotion)
    case remainder(RemainderDevotion)
    
    public var id: UUID {
        switch self {
            case .amount(let a): a.id
            case .percent(let p): p.id
            case .remainder(let r): r.id
        }
    }
    public var name: String {
        get {
            switch self {
                case .amount(let a): a.name
                case .percent(let p): p.name
                case .remainder(let r): r.name
            }
        }
        set {
            switch self {
                case .amount(let a): a.name = newValue
                case .percent(let p): p.name = newValue
                case .remainder(let r): r.name = newValue
            }
        }
    }
    public var account: SubAccount? {
        get {
            switch self {
                case .amount(let a): a.account
                case .percent(let p): p.account
                case .remainder(let r): r.account
            }
        }
        set {
            switch self {
                case .amount(let a): a.account = newValue
                case .percent(let p): p.account = newValue
                case .remainder(let r): r.account = newValue
            }
        }
    }
    public var group: DevotionGroup {
        get {
            switch self {
                case .amount(let a): a.group
                case .percent(let p): p.group
                case .remainder(let r): r.group
            }
        }
        set {
            switch self {
                case .amount(let a): a.group = newValue
                case .percent(let p): p.group = newValue
                case .remainder(let r): r.group = newValue
            }
        }
    }
}

@Observable
public class DevotionSnapshotBase : Identifiable, Hashable, Equatable, ElementSnapshot {
    public init() {
        self.id = UUID()
        self.name = ""
        self.group = .want
        self.account = nil
    }
    public init<T>(_ from: T) where T: DevotionBase {
        self.id = from.id;
        self.name = from.name
        self.group = from.group
        self.account = from.account
    }
    
    public let id: UUID;
    public var name: String;
    public var group: DevotionGroup;
    public var account: SubAccount?;
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        fatalError()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(group)
        hasher.combine(account)
    }
    public static func ==(lhs: DevotionSnapshotBase, rhs: DevotionSnapshotBase) -> Bool {
        lhs.name == rhs.name && lhs.group == rhs.group && lhs.account == rhs.account
    }
}
public enum AnyDevotionSnapshot : Identifiable, Hashable, Equatable {
    case amount(AmountDevotionSnapshot)
    case percent(PercentDevotionSnapshot)
    
    public var id: UUID {
        switch self {
            case .amount(let a): a.id
            case .percent(let p): p.id
        }
    }
    public var name: String {
        get {
            switch self {
                case .amount(let a): a.name
                case .percent(let p): p.name
            }
        }
        set {
            switch self {
                case .amount(let a): a.name = newValue
                case .percent(let p): p.name = newValue
            }
        }
    }
    public var account: SubAccount? {
        get {
            switch self {
                case .amount(let a): a.account
                case .percent(let p): p.account
            }
        }
        set {
            switch self {
                case .amount(let a): a.account = newValue
                case .percent(let p): p.account = newValue
            }
        }
    }
    public func amount(_ total: Decimal) -> Decimal {
        switch self {
            case .amount(let a): a.amount.rawValue
            case .percent(let p): p.amount.rawValue * total
        }
    }
    public var group: DevotionGroup {
        get {
            switch self {
                case .amount(let a): a.group
                case .percent(let p): p.group
            }
        }
        set {
            switch self {
                case .amount(let a): a.group = newValue
                case .percent(let p): p.group = newValue
            }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
            case .amount(let a): hasher.combine(a)
            case .percent(let p): hasher.combine(p)
        }
    }
    public static func ==(lhs: AnyDevotionSnapshot, rhs: AnyDevotionSnapshot) -> Bool {
        switch (lhs, rhs) {
            case (.amount(let a), .amount(let b)): a == b
            case (.percent(let a), .percent(let b)): a == b
            default: false
        }
    }
}

@Model
public final class AmountDevotion : DevotionBase {
    public convenience init() {
        self.init(name: "", amount: 0)
    }
    public init(name: String, amount: Decimal, parent: BudgetInstance? = nil, account: SubAccount? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
        self.id = id
        self.parent = parent;
        self.name = name;
        self.amount = amount;
        self.account = account
        self._group = group.rawValue
    }
    
    public var id: UUID;
    public var name: String;
    public var amount: Decimal;
    private var _group: DevotionGroup.RawValue
    public var group: DevotionGroup {
        get {
            DevotionGroup(rawValue: _group) ?? .want
        }
        set {
            _group = newValue.rawValue
        }
    }
    @Relationship
    public var parent: BudgetInstance?;
    @Relationship
    public var account: SubAccount?;
    
    public func makeSnapshot() -> AmountDevotionSnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> AmountDevotionSnapshot {
        .init()
    }
    public func update(_ snap: AmountDevotionSnapshot, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.amount = snap.amount.rawValue
        self.account = snap.account
        self.group = snap.group
    }
}
@Observable
public final class AmountDevotionSnapshot : DevotionSnapshotBase {
    public override init() {
        self.amount = .init()
        super.init()
    }
    public init(_ from: AmountDevotion) {
        self.amount = .init(rawValue: from.amount)
        super.init(from)
    }
    
    public var amount: CurrencyValue;
    
    public override func validate(unique: UniqueEngine) -> [ValidationFailure] {
        fatalError()
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        super.hash(into: &hasher)
    }
    public static func ==(lhs: AmountDevotionSnapshot, rhs: AmountDevotionSnapshot) -> Bool {
        (lhs as DevotionSnapshotBase == rhs as DevotionSnapshotBase) && lhs.amount == rhs.amount
    }
}

@Model
public final class PercentDevotion : DevotionBase {
    public convenience init() {
        self.init(name: "", amount: 0)
    }
    public init(name: String, amount: Decimal, parent: BudgetInstance? = nil, account: SubAccount? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
        self.id = id
        self.parent = parent;
        self.name = name;
        self.amount = amount
        self.account = account
        self._group = group.rawValue
    }
    
    public var id: UUID;
    public var name: String;
    public var amount: Decimal;
    private var _group: DevotionGroup.RawValue
    public var group: DevotionGroup {
        get {
            DevotionGroup(rawValue: _group) ?? .want
        }
        set {
            _group = newValue.rawValue
        }
    }
    @Relationship
    public var parent: BudgetInstance?;
    @Relationship
    public var account: SubAccount?;
    
    public func makeSnapshot() -> PercentDevotionSnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> PercentDevotionSnapshot {
        .init()
    }
    public func update(_ snap: PercentDevotionSnapshot, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.amount = snap.amount.rawValue
        self.account = snap.account
        self.group = snap.group
    }
}
@Observable
public final class PercentDevotionSnapshot : DevotionSnapshotBase {
    public override init() {
        self.amount = .init()
        super.init()
    }
    public init(_ from: PercentDevotion) {
        self.amount = .init(rawValue: from.amount)
        super.init(from)
    }
    
    public var amount: PercentValue;
    
    public override func validate(unique: UniqueEngine) -> [ValidationFailure] {
        fatalError()
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        super.hash(into: &hasher)
    }
    public static func ==(lhs: PercentDevotionSnapshot, rhs: PercentDevotionSnapshot) -> Bool {
        (lhs as DevotionSnapshotBase == rhs as DevotionSnapshotBase) && lhs.amount == rhs.amount
    }
}

@Model
public final class RemainderDevotion : DevotionBase {
    public convenience init() {
        self.init(name: "")
    }
    public init(name: String, parent: BudgetInstance? = nil, account: SubAccount? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
        self.id = id
        self.parent = parent;
        self.name = name;
        self.account = account
        self._group = group.rawValue
    }
    
    public var id: UUID;
    public var name: String
    private var _group: DevotionGroup.RawValue
    public var group: DevotionGroup {
        get {
            DevotionGroup(rawValue: _group) ?? .want
        }
        set {
            _group = newValue.rawValue
        }
    }
    @Relationship
    public var parent: BudgetInstance?;
    @Relationship
    public var account: SubAccount?;
    
    public func makeSnapshot() -> DevotionSnapshotBase {
        .init(self)
    }
    public static func makeBlankSnapshot() -> DevotionSnapshotBase {
        .init()
    }
    public func update(_ snap: DevotionSnapshotBase, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.account = snap.account
        self.group = snap.group
    }
}
