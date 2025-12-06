//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    @Model
    public final class BillDatapoint : Identifiable {
        public init(_ amount: Decimal?, index: Int, parent: Bill?) {
            self.id = index
            self.parent = parent
            self.amount = amount
        }
        
        /// Where the data point lies in the greater storage array.
        public var id: Int = 0;
        /// How much the datapoint cost
        public var amount: Decimal? = nil;
        /// The owning utility.
        @Relationship
        public var parent: Bill?;
    }
    
    /// A data set pertaining to a same-amount periodic charge.
    @Model
    public final class Bill : Identifiable {
        /// Creates a bill while filling in all fields.
        public init(name: String, kind: BillsKind, amount: Decimal, company: String, location: String?, start: Date, end: Date?, period: TimePeriods) {
            self.name = name
            self._amount = amount
            self.startDate = start
            self.endDate = end
            self.company = company
            self.location = location
            self.kind = kind
            self.period = period
            self.autoPay = false;
            self.id = UUID();
        }
        
        public var id: UUID;
        public var name: String;
        public internal(set) var _amount: Decimal;
        public var startDate: Date;
        public var endDate: Date?;
        public var company: String;
        public var location: String?;
        public var autoPay: Bool;
        /// The internal raw value used to store the kind.
        public var kind: BillsKind;
        /// The internall raw value used to store the period.
        public var period: TimePeriods;
        
        @Relationship(deleteRule: .cascade, inverse: \BillDatapoint.parent)
        public var history: [BillDatapoint] = [];
        
        @Transient
        internal var _nextDueDate: Date? = nil;
        @Transient
        internal var _oldHash: Int = 0;
    }
}
