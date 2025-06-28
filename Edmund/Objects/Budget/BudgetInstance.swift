//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import Foundation
import SwiftData
import SwiftUI

public final class BudgetUpdateRecord<T> where T: DevotionBase {
    public init(_ devotion: T) {
        self.devotion = devotion
        self.visisted = false
    }
    
    public var devotion: T;
    public var visisted: Bool;
    
    public static func updateOrInsert(_ snap: T.Snapshot, old: Dictionary<T.ID, BudgetUpdateRecord<T>>, modelContext: ModelContext?, list: inout [T]) where T: PersistentModel {
        let new: T;
        if let target = old[snap.id] {
            target.devotion.update(snap)
            target.visisted = true
            
            new = target.devotion
        }
        else {
            new = T()
            new.update(snap)
            modelContext?.insert(new)
        }
        
        list.append(new)
    }
}

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
public final class BudgetInstance : Identifiable {
    public convenience init() {
        self.init(name: "", amount: 0, kind: .pay)
    }
    public init(name: String, amount: Decimal, kind: IncomeKind, account: SubAccount? = nil, lastViewed: Date = .now, lastUpdated: Date = .now, amounts: [AmountDevotion] = [], percents: [PercentDevotion] = [], remainder: RemainderDevotion? = nil) {
        self.name = name
        self.amount = amount
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
    
    @MainActor
    public func apply(_ snap: BudgetInstanceSnapshot) {
        // These types are UUID -> (Devotion, Bool). The bool determines if this value was updated at all from the previous system. If it was not, they will be deleted at the end.
        let oldAmounts = Dictionary(uniqueKeysWithValues: self.amounts.map { ($0.id, BudgetUpdateRecord($0)) })
        let oldPercents = Dictionary(uniqueKeysWithValues: self.percents.map { ($0.id, BudgetUpdateRecord($0) ) })
        
        // All old & new elements will be added to this list. That way
        var newAmounts: [AmountDevotion] = [];
        var newPercents: [PercentDevotion] = [];
        
        if let oldRemainder = self.remainder, snap.hasRemainder {
            oldRemainder.update(snap.remainder)
        }
        else if let oldRemainder = self.remainder, !snap.hasRemainder {
            modelContext?.delete(oldRemainder)
            self.remainder = nil
        }
        else if snap.hasRemainder && self.remainder == nil {
            let new = RemainderDevotion()
            new.update(snap.remainder)
            
            self.remainder = new
            modelContext?.insert(new)
        } // At this point, there is no remainder in the snapshot, and the current remainder is nil, so nothing to do with it.
        
        for devotion in snap.devotions {
            switch devotion {
                case .amount(let amount):
                    BudgetUpdateRecord.updateOrInsert(amount, old: oldAmounts, modelContext: modelContext, list: &newAmounts)
                case .percent(let percent):
                    BudgetUpdateRecord.updateOrInsert(percent, old: oldPercents, modelContext: modelContext, list: &newPercents)
            }
        }
        
        // Removes any un-visisted amounts
        let filteredAmounts = oldAmounts.values.filter { !$0.visisted }
        let filteredPercents = oldPercents.values.filter { !$0.visisted }
        
        for amount in filteredAmounts {
            modelContext?.delete(amount.devotion)
        }
        for percent in filteredPercents {
            modelContext?.delete(percent.devotion)
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
        let result = BudgetInstance(name: "Example Budget", amount: 450, kind: .pay)
        
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
}

@Observable
public final class BudgetInstanceSnapshot {
    init(_ from: BudgetInstance) {
        self.name = from.name;
        self.amount = .init(rawValue: from.amount)
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
    public var devotions: [DevotionSnapshot];
    public var hasRemainder: Bool;
    public var remainder: RemainderDevotionSnapshot;
    
}
public enum DevotionSnapshot : Identifiable {
    case amount(AmountDevotionSnapshot)
    case percent(PercentDevotionSnapshot)
    
    public var id: UUID {
        switch self {
            case .amount(let a): a.id
            case .percent(let p): p.id
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

public protocol DevotionBase : Identifiable<UUID> {
    associatedtype Snapshot: Identifiable<UUID>
    
    init()
    
    var name: String { get set }
    var account: SubAccount? { get set }
    var group: DevotionGroup { get set }
    
    func makeSnapshot() -> Self.Snapshot;
    func update(_ snap: Self.Snapshot)
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

@Model
public final class AmountDevotion : DevotionBase  {
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
    public func update(_ snap: AmountDevotionSnapshot) {
        self.name = snap.name
        self.amount = snap.amount.rawValue
        self.account = snap.account
    }
}
@Observable
public final class AmountDevotionSnapshot : Identifiable {
    public init(_ from: AmountDevotion) {
        self.name = from.name;
        self.amount = .init(rawValue: from.amount)
        self.account = from.account;
        self.id = from.id
        self.group = from.group
    }
    
    public var id: UUID;
    public var name: String;
    public var amount: CurrencyValue;
    public var account: SubAccount?;
    public var group: DevotionGroup;
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
    public func update(_ snap: PercentDevotionSnapshot) {
        self.name = snap.name;
        self.amount = snap.amount.rawValue
        self.account = snap.account
    }
}
@Observable
public final class PercentDevotionSnapshot : Identifiable {
    public init(_ from: PercentDevotion) {
        self.name = from.name;
        self.amount = .init(rawValue: from.amount)
        self.account = from.account;
        self.id = from.id
        self.group = from.group
    }
    
    public var id: UUID;
    public var name: String;
    public var amount: PercentValue;
    public var account: SubAccount?;
    public var group: DevotionGroup;
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
    
    public func makeSnapshot() -> RemainderDevotionSnapshot {
        .init(self)
    }
    public func update(_ snap: RemainderDevotionSnapshot) {
        self.name = snap.name
        self.account = snap.account
    }
}
@Observable
public final class RemainderDevotionSnapshot : Identifiable {
    public init() {
        self.name = ""
        self.account = nil;
        self.id = UUID()
        self.group = .want
    }
    public init(_ from: RemainderDevotion) {
        self.name = from.name;
        self.account = from.account;
        self.id = from.id
        self.group = from.group
    }
    
    public var name: String;
    public var account: SubAccount?;
    public var group: DevotionGroup;
    public var id: UUID;
}
