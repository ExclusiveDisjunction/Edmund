//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    /// A data set pertaining to a same-amount periodic charge.
    @Model
    public final class Bill : Identifiable {
        /// Creates a bill while filling in all fields.
        public init(name: String, kind: StrictBillsKind, amount: Decimal, company: String, location: String?, start: Date, end: Date?, period: TimePeriods) {
            self.name = name
            self.amount = amount
            self.startDate = start
            self.endDate = end
            self.company = company
            self.location = location
            self._kind = kind.rawValue
            self._period = period.rawValue
            self.id = UUID();
        }
        public init(migrate: EdmundModelsV1.Bill) {
            self.name = migrate.name
            self.amount = migrate.amount
            self.startDate = migrate.startDate
            self.endDate = migrate.endDate
            self.company = migrate.company
            self.location = migrate.location
            self._kind = migrate._kind
            self._period = migrate._period
            self.id = UUID();
        }
        
        public var id: UUID;
        public var name: String = "";
        public var amount: Decimal = 0.0;
        public var startDate: Date = Date.now;
        public var endDate: Date? = nil;
        public var company: String = "";
        public var location: String? = nil;
        public var autoPay: Bool = true;
        
        @Transient
        internal var _nextDueDate: Date? = nil;
        @Transient
        internal var _oldHash: Int = 0;
        
        /// The internal raw value used to store the kind.
        public internal(set) var _kind: StrictBillsKind.RawValue;
        /// The internall raw value used to store the period.
        public internal(set) var _period: TimePeriods.RawValue;
    }
    
    /// An instance used to keep the order of utility data points.
    @Model
    public class UtilityDatapoint : Identifiable {
        public init(_ amount: Decimal = 0, index: Int, parent: Utility? = nil) {
            self.id = index
            self.parent = parent
            self.amount = amount
        }
        public init(migrate: EdmundModelsV1.UtilityDatapoint) {
            self.id = migrate.id
            self.parent = nil
            self.amount = migrate.amount
        }
        
        /// Where the data point lies in the greater storage array.
        public var id: Int;
        /// How much the datapoint cost
        public var amount: Decimal;
        /// The owning utility.
        @Relationship
        public var parent: Utility?;
    }
    
    /// Represents a variable-cost bill
    @Model
    public final class Utility : Identifiable {
        /// Creates the utility with all fields
        public init(_ name: String, amounts: [Decimal], company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
            self.name = name
            self.startDate = start
            self.endDate = end
            self._period = period.rawValue
            self.company = company
            self.location = location
            self.id = UUID();
            self._points = amounts.enumerated().map { .init($0.element, index: $0.offset, parent: self) };
        }
        public init(migrate: EdmundModelsV1.Utility) {
            self.name = migrate.name
            self.startDate = migrate.startDate
            self.endDate = migrate.endDate
            self._period = migrate.rawPeriod
            self.company = migrate.company
            self.location = migrate.location
            self._points = migrate._points?.map { UtilityDatapoint(migrate: $0) }
            self.id = UUID();
        }
        
        public var id: UUID;
        public var name: String = "";
        public var startDate: Date = Date.now;
        public var endDate: Date? = nil;
        public var company: String = "";
        public var location: String? = nil;
        public var autoPay: Bool = true;
        public internal(set) var _period: TimePeriods.RawValue;
        
        @Relationship(deleteRule: .cascade, inverse: \UtilityDatapoint.parent)
        public internal(set) var _points: [UtilityDatapoint]? = nil;
        
        /// The previously calculated next due date, if the hash is deemed to match.
        @Transient
        internal var _nextDueDate: Date? = nil;
        /// A hash of the start date, end date, and period. This is used to determine if the next due date is still valid.
        @Transient
        internal var _oldHash: Int = 0;
        
        @Transient
        public let kind: BillsKind = BillsKind.utility
        
        
        public func makeSnapshot() -> UtilitySnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> UtilitySnapshot {
            .init()
        }
    }
}
