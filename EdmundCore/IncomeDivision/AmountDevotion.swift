//
//  AmountDevotion.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension AmountDevotion : DevotionBase {
    public convenience init() {
        self.init(name: "", amount: 0)
    }
    public convenience init(snapshot: DevotionSnapshot<CurrencyValue>, unique: UniqueEngine) {
        self.init(
            name: snapshot.name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: snapshot.value.rawValue,
            parent: nil, account: snapshot.account,
            group: snapshot.group
        )
    }
    
    public var group: DevotionGroup {
        get {
            DevotionGroup(rawValue: _group) ?? .want
        }
        set {
            _group = newValue.rawValue
        }
    }
    
    public func duplicate() -> AmountDevotion {
        return .init(name: self.name, amount: self.amount, parent: nil, account: self.account, group: self.group)
    }
    
    public func makeSnapshot() -> DevotionSnapshot<CurrencyValue> {
        .init(base: self, value: .init(rawValue: self.amount), min: 0);
    }
    public static func makeBlankSnapshot() -> DevotionSnapshot<CurrencyValue> {
        .init(value: .init(), min: 0);
    }
    public func update(_ snap: DevotionSnapshot<CurrencyValue>, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.amount = snap.value.rawValue
        self.account = snap.account
        self.group = snap.group
    }
}
