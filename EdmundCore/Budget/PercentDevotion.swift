//
//  PercentDevotions.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1 {
    @Model
    public final class PercentDevotion : DevotionBase {
        public convenience init() {
            self.init(name: "", amount: 0)
        }
        public init(name: String, amount: Decimal, parent: IncomeDivision? = nil, account: SubAccount? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
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
        public var parent: IncomeDivision?;
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
}

public typealias PercentDevotion = EdmundModelsV1.PercentDevotion

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
    
    public override func validate(unique: UniqueEngine) -> ValidationFailure? {
        return .internalError
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        super.hash(into: &hasher)
    }
    public static func ==(lhs: PercentDevotionSnapshot, rhs: PercentDevotionSnapshot) -> Bool {
        (lhs as DevotionSnapshotBase == rhs as DevotionSnapshotBase) && lhs.amount == rhs.amount
    }
}
