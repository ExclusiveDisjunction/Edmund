//
//  IncomeDivisions.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    @Model
    public final class AmountDevotion : Identifiable {
        public init(name: String, amount: Decimal, parent: IncomeDivision? = nil, account: Account? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
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
        public internal(set) var _group: DevotionGroup.RawValue
        
        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: Account?;
    }
    
    @Model
    public final class PercentDevotion : Identifiable {
        public init(name: String, amount: Decimal, parent: IncomeDivision? = nil, account: Account? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
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
        public internal(set) var _group: DevotionGroup.RawValue
        
        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: Account?;
    }
    
    @Model
    public final class RemainderDevotion : Identifiable {
        public init(name: String, parent: IncomeDivision? = nil, account: Account? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
            self.id = id
            self.parent = parent;
            self.name = name;
            self.account = account
            self._group = group.rawValue
        }
        
        public var id: UUID;
        public var name: String
        public internal(set) var _group: DevotionGroup.RawValue
        
        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: Account?;
    }
    
    @Model
    public final class IncomeDivision : Identifiable {
        public init(name: String, amount: Decimal, kind: IncomeKind, depositTo: Account? = nil, lastViewed: Date = .now, lastUpdated: Date = .now, amounts: [AmountDevotion] = [], percents: [PercentDevotion] = [], remainder: RemainderDevotion? = nil) {
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
        public internal(set) var _kind: IncomeKind.RawValue;
        public var lastUpdated: Date;
        public var lastViewed: Date;
        
        @Relationship
        public var parent: BudgetMonth?;
        @Relationship
        public var depositTo: Account?;
        @Relationship(deleteRule: .cascade, inverse: \AmountDevotion.parent)
        public var amounts: [AmountDevotion];
        @Relationship(deleteRule: .cascade, inverse: \PercentDevotion.parent)
        public var percents: [PercentDevotion];
        @Relationship(deleteRule: .cascade, inverse: \RemainderDevotion.parent)
        public var remainder: RemainderDevotion?;
    }
}
