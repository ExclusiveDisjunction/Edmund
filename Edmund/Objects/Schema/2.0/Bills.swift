//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV2 {
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
            self.id = UUID();
        }
        
        public var id: UUID = UUID();
        public var name: String = "";
        public internal(set) var _amount: Decimal = 0.0;
        public var startDate: Date = Date.now;
        public var endDate: Date? = nil;
        public var company: String = "";
        public var location: String? = nil;
        public var autoPay: Bool = true;
        public var kind: BillsKind = BillsKind.bill;
        public var period: TimePeriods = TimePeriods.monthly;
        
        @Relationship(deleteRule: .cascade, inverse: \BillDatapoint.parent)
        public  var history: [BillDatapoint] = [];
        
        @Transient
        internal var _nextDueDate: Date? = nil;
        @Transient
        internal var _oldHash: Int = 0;
        
        @Transient
        internal var _historyHash: Int = 0;
        @Transient
        internal var _historyAverage: Decimal = 0;
    }
}
