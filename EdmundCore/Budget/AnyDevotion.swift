//
//  AnyDevotion.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import Foundation

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
