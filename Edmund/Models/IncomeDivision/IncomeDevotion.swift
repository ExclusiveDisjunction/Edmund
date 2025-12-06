//
//  DevotionBase.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation

public enum DevotionGroup : Int, Identifiable, CaseIterable, Codable {
    case need
    case want
    case savings
    
    public var asString: String {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
        }
    }
    
    public var id: Self { self }
}

public enum DevotionSnapshotAmount : Hashable, Equatable {
    case amount(CurrencyValue)
    case percent(PercentValue)
    case remainder
}

extension IncomeDevotion : SnapshotConstructableElement {
    public convenience init() {
        self.init(name: "", amount: .amount(0))
    }
    public convenience init(snapshot: IncomeDevotionSnapshot, unique: UniqueEngine) {
        self.init()
        self.update(snapshot, unique: unique)
    }
    
    public func duplicate() -> IncomeDevotion {
        return IncomeDevotion(name: self.name, amount: self.amount, parent: nil, account: self.account, group: self.group)
    }
    
    public func makeSnapshot() -> IncomeDevotionSnapshot {
        IncomeDevotionSnapshot(self)
    }
    public static func makeBlankSnapshot() -> IncomeDevotionSnapshot {
        IncomeDevotionSnapshot()
    }
    public func update(_ snap: IncomeDevotionSnapshot, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.amount = switch snap.amount {
            case .amount(let v): .amount(v.rawValue)
            case .percent(let v): .percent(v.rawValue)
            case .remainder: .remainder
        }
        self.account = snap.account
        self.group = snap.group
    }
}

@Observable
public class IncomeDevotionSnapshot : Identifiable, Hashable, Equatable, ElementSnapshot {
    public init() {
        self.id = UUID()
        self.name = ""
        self.group = .want
        self.account = nil
        self.amount = .amount(CurrencyValue())
    }
    public convenience init(withPercent: Decimal) {
        self.init()
        self.amount = .percent(PercentValue(rawValue: withPercent))
    }
    public convenience init(withAmount: Decimal) {
        self.init()
        self.amount = .amount(CurrencyValue(rawValue: withAmount))
    }
    public static func newRemainder() -> IncomeDevotionSnapshot {
        let result = IncomeDevotionSnapshot();
        result.amount = .remainder
        
        return result;
    }
    public init(_ from: IncomeDevotion) {
        self.id = from.id;
        self.name = from.name;
        self.group = from.group;
        self.account = from.account
        self.amount = switch from.amount {
            case .amount(let v): .amount(CurrencyValue(rawValue: v))
            case .percent(let v): .percent(PercentValue(rawValue: v))
            case .remainder: .remainder
        }
    }
    
    public let id: UUID;
    public var name: String;
    public var group: DevotionGroup;
    public var account: Account?;
    public var amount: DevotionSnapshotAmount;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        switch self.amount {
            case .amount(let v): if v < 0 { return .negativeAmount }
            case .percent(let v): if v < 0 { return .negativeAmount }
                else if v > 1 { return .tooLargeAmount }
            case .remainder: break
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            account == nil {
            return .empty
        }
        
        return nil;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(group)
        hasher.combine(account)
        hasher.combine(amount)
    }
    public static func ==(lhs: IncomeDevotionSnapshot, rhs: IncomeDevotionSnapshot) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.group == rhs.group &&
        lhs.account == rhs.account &&
        lhs.amount == rhs.amount
    }
}
