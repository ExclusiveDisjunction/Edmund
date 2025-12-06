//
//  IncomeDivisions.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    public enum DevotionAmount : Codable, Equatable, Hashable {
        case amount(Decimal)
        case percent(Decimal)
        case remainder
    }
    
    @Model
    public final class IncomeDevotion : Identifiable {
        public init(name: String, amount: DevotionAmount, parent: IncomeDivision? = nil, account: Account? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
            self.id = id
            self.parent = parent
            self.name = name;
            self.account = account;
            self.amount = amount;
            self.group = group;
        }
        
        public var id: UUID;
        public var name: String;
        public var amount: DevotionAmount;
        public var group: DevotionGroup;
        
        @Relationship
        public var parent: IncomeDivision?;
        @Relationship
        public var account: Account?;
    }
    
    @Model
    public final class IncomeDivision : Identifiable {
        public init(name: String, amount: Decimal, kind: IncomeKind, depositTo: Account? = nil, lastViewed: Date = .now, lastUpdated: Date = .now, devotions: [IncomeDevotion] = []) {
            self.name = name
            self.amount = amount
            self.depositTo = depositTo
            self._kind = kind.rawValue
            self.lastViewed = lastViewed
            self.lastUpdated = lastUpdated
            self.devotions = devotions
            self.parent = nil;
            self.isFinalized = false;
            self.id = UUID();
        }
        
        public var id: UUID;
        public var name: String;
        public var amount: Decimal;
        public var isFinalized: Bool;
        public internal(set) var _kind: IncomeKind.RawValue = 0;
        public var lastUpdated: Date;
        public var lastViewed: Date;
        
        @Relationship
        public var parent: BudgetMonth?;
        @Relationship
        public var depositTo: Account?;
        @Relationship(deleteRule: .cascade, inverse: \IncomeDevotion.parent)
        public var devotions: [IncomeDevotion];
    }
}
