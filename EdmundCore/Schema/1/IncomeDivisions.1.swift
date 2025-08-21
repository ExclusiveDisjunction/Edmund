//
//  IncomeDivisions.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import Foundation
import SwiftData

extension EdmundModelsV1 {
    public enum DevotionGroup : Int, Identifiable, CaseIterable {
        case need
        case want
        case savings
        
        public var id: Self { self }
    }
    public enum IncomeKind: Int, CaseIterable, Identifiable {
        case pay
        case gift
        case donation
        
        public var id: Self { self }
    }
    
    @Model
    public final class AmountDevotion : Identifiable {
        public init(name: String, amount: Decimal, parent: IncomeDivision?, account: SubAccount?, group: DevotionGroup, id: UUID = UUID()) {
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

        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: SubAccount?;
    }
    
    @Model
    public final class PercentDevotion : Identifiable {
        public init(name: String, amount: Decimal, parent: IncomeDivision?, account: SubAccount?, group: DevotionGroup, id: UUID = UUID()) {
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
        public private(set) var _group: DevotionGroup.RawValue
        
        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: SubAccount?;
    }
    
    @Model
    public final class RemainderDevotion : Identifiable {
        public init(name: String, parent: IncomeDivision?, account: SubAccount?, group: DevotionGroup, id: UUID = UUID()) {
            self.id = id
            self.parent = parent;
            self.name = name;
            self.account = account
            self._group = group.rawValue
        }
        
        public var id: UUID;
        public var name: String
        public private(set) var _group: DevotionGroup.RawValue

        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: SubAccount?;
    }
    
    @Model
    public final class IncomeDivision : Identifiable {
        public init(name: String, amount: Decimal, kind: IncomeKind, depositTo: SubAccount?, lastViewed: Date, lastUpdated: Date, amounts: [AmountDevotion], percents: [PercentDevotion], remainder: RemainderDevotion?) {
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
        public private(set) var _kind: IncomeKind.RawValue;

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
    }
}
