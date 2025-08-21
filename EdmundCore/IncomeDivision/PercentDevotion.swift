//
//  PercentDevotions.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension PercentDevotion : DevotionBase {
    public convenience init() {
        self.init(name: "", amount: 0)
    }
    public convenience init(snapshot: DevotionSnapshot<PercentValue>, unique: UniqueEngine) {
        self.init(
            name: snapshot.name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: snapshot.value.rawValue,
            parent: nil,
            account: snapshot.account,
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
    
    public func duplicate() -> PercentDevotion {
        return .init(name: self.name, amount: self.amount, parent: nil, account: self.account, group: self.group)
    }
    
    public func makeSnapshot() -> DevotionSnapshot<PercentValue> {
        .init(base: self, value: .init(rawValue: self.amount), min: 0, max: 1)
    }
    public static func makeBlankSnapshot() -> DevotionSnapshot<PercentValue> {
        .init(value: .init(), min: 0, max: 1)
    }
    public func update(_ snap: DevotionSnapshot<PercentValue>, unique: UniqueEngine) {
        self.name = snap.name.trimmingCharacters(in: .whitespaces)
        self.amount = snap.value.rawValue
        self.account = snap.account
        self.group = snap.group
    }
}
