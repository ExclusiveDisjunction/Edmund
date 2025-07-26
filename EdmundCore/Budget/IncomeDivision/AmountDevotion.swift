//
//  AmountDevotion.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1 {
    @Model
    public final class AmountDevotion : DevotionBase {
        public convenience init() {
            self.init(name: "", amount: 0)
        }
        public init(name: String, amount: Decimal, parent: IncomeDivision? = nil, account: SubAccount? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
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
        public var parent: IncomeDivision?;
        @Relationship
        public var account: SubAccount?;
        
        public func duplicate() -> AmountDevotion {
            return .init(name: self.name, amount: self.amount, parent: nil, account: self.account, group: self.group)
        }
        
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
}

public typealias AmountDevotion = EdmundModelsV1.AmountDevotion

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
    
    public override func validate(unique: UniqueEngine) -> ValidationFailure? {
        if let result = super.validate(unique: unique) {
            return result
        }
        
        if amount.rawValue < 0 {
            return .negativeAmount
        }
        
        return nil
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        super.hash(into: &hasher)
    }
    public static func ==(lhs: AmountDevotionSnapshot, rhs: AmountDevotionSnapshot) -> Bool {
        (lhs as DevotionSnapshotBase == rhs as DevotionSnapshotBase) && lhs.amount == rhs.amount
    }
}
