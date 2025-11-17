//
//  AmountDevotion.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension IncomeDevotion {
    public convenience init() {
        self.init(name: "", kind: .amount(0))
    }
    
    public func duplicate() -> IncomeDevotion {
        return .init(name: self.name, kind: self.kind, parent: nil, account: self.account, group: self.group)
    }
}

extension IncomeDevotion : SnapshotConstructableElement {
    public convenience init(snapshot: IncomeDevotionSnapshot, unique: UniqueEngine) {
        self.init();
        self.update(snapshot, unique: unique)
    }
    
    public func makeSnapshot() -> IncomeDevotionSnapshot {
        IncomeDevotionSnapshot(from: self)
    }
    public static func makeBlankSnapshot() -> IncomeDevotionSnapshot {
        IncomeDevotionSnapshot()
    }
    public func update(_ snap: IncomeDevotionSnapshot, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.kind = snap.kind.toDevotionKind();
        self.account = snap.account;
        self.group = snap.group
    }
}

public enum IncomeDevotionKindSnapshot : Equatable, Hashable {
    case amount(CurrencyValue)
    case percent(PercentValue)
    case remainder
    
    public static func fromDevotionKind(kind: DevotionKind) -> IncomeDevotionKindSnapshot {
        switch kind {
            case .amount(let a): .amount(.init(rawValue: a))
            case .percent(let p): .percent(.init(rawValue: p))
            case .remainder: .remainder
        }
    }
    
    public func toDevotionKind() -> DevotionKind {
        switch self {
            case .amount(let a): .amount(a.rawValue)
            case .percent(let p): .percent(p.rawValue)
            case .remainder: .remainder
        }
    }
}

@Observable
public class IncomeDevotionSnapshot : ElementSnapshot, Identifiable {
    public init() {
        self.name = "";
        self.group = .want;
        self.account = nil;
        self.kind = .amount(.init())
        self.id = UUID();
    }
    public init(from: IncomeDevotion) {
        self.name = from.name
        self.kind = .fromDevotionKind(kind: from.kind)
        self.account = from.account
        self.group = from.group
        self.id = from.id;
    }
    
    @ObservationIgnored public let id: UUID;
    public var name: String;
    public var group: DevotionGroup;
    public var account: Account?;
    public var kind: IncomeDevotionKindSnapshot;
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines);
        guard !name.isEmpty && account != nil else {
            return .empty
        }
        
        switch kind {
            case .amount(let a):
                guard a >= 0 else {
                    return .negativeAmount
                }
            case .percent(let p):
                guard p >= 0 else {
                    return .negativeAmount
                }
                guard p <= 1 else {
                    return .tooLargeAmount
                }
            default: ()
        }
        
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(account)
        hasher.combine(group)
        hasher.combine(kind)
    }
    
    public static func ==(lhs: IncomeDevotionSnapshot, rhs: IncomeDevotionSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.account == rhs.account && lhs.group == rhs.group && lhs.kind == rhs.kind
    }
}
