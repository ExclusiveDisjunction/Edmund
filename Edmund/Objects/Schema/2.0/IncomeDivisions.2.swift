//
//  IncomeDivisions.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

public enum DevotionKind : Codable, Equatable, Hashable {
    case amount(Decimal)
    case percent(Decimal)
    case remainder
}
public enum DevotionGroup : Int, Identifiable, CaseIterable {
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
public enum IncomeKind: Int, CaseIterable, Identifiable {
    case pay
    case gift
    case donation
    
    public var id: Self { self }
}

extension EdmundModelsV2 {
    @Model
    public final class IncomeDevotion : Identifiable {
        public init(name: String, kind: DevotionKind, parent: IncomeDivision? = nil, account: Account? = nil, group: DevotionGroup = .want, id: UUID = UUID()) {
            self.id = id
            self.parent = parent;
            self.name = name;
            self.account = account
            self.group = group
            self.kind = kind
        }
        
        public var id: UUID = UUID();
        public var name: String = "";
        public var group: DevotionGroup = DevotionGroup.want;
        public var kind: DevotionKind = DevotionKind.amount(0)
        
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
            self.kind = kind
            self.lastViewed = lastViewed
            self.lastUpdated = lastUpdated
            self.devotions = devotions
            self.id = UUID();
        }
        
        public var id: UUID = UUID();
        public var name: String = "";
        public var amount: Decimal = 0;
        public var isFinalized: Bool = false;
        public var kind: IncomeKind = IncomeKind.pay;
        public var lastUpdated: Date = Date.distantPast;
        public var lastViewed: Date = Date.distantPast;
        
        @Transient
        @ObservationIgnored
        internal var _devotionsHash: Int = 0;
        @Transient
        @ObservationIgnored
        internal var _devotionsTotal: Decimal = 0;
        @Transient
        @ObservationIgnored
        internal var _remaindersCount: Int = 0;
        
        @Relationship
        public var parent: BudgetMonth?;
        @Relationship
        public var depositTo: Account?;
        @Relationship(deleteRule: .cascade, inverse: \IncomeDevotion.parent)
        public var devotions: [IncomeDevotion];
    }
}
