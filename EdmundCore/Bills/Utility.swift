//
//  Utilities.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import Foundation;

extension EdmundModelsV1 {
    /// Represents a variable-cost bill
    @Model
    public final class Utility: BillBase, UniqueElement, IsolatedDefaultableElement, NamedElement {
        public typealias Snapshot = UtilitySnapshot
        
        /// Creates the utility with blank values.
        public convenience init() {
            self.init("", amounts: [], company: "", start: Date.now)
        }
        /// Creates the utility with all fields
        public init(_ name: String, amounts: [Decimal], company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
            self.name = name
            self.startDate = start
            self.endDate = end
            self.rawPeriod = period.rawValue
            self.company = company
            self.location = location
            self._points = amounts.enumerated().map { .init($0.element, index: $0.offset, parent: self) };
        }
        
        public static let objId: ObjectIdentifier = .init((any BillBase).self)
        
        public var id: BillBaseID {
            .init(name: name, company: company, location: location)
        }
        public var name: String = "";
        public var startDate: Date = Date.now;
        public var endDate: Date? = nil;
        public var company: String = "";
        public var location: String? = nil;
        public var autoPay: Bool = true
        
        @Relationship(deleteRule: .cascade, inverse: \UtilityDatapoint.parent)
        private var _points: [UtilityDatapoint]? = nil;
        
        public var points: [Decimal] {
            get {
                guard let points = self._points else {
                    return [];
                }
                
                return points.sorted(using: SortDescriptor(\.id, order: .forward)).map { $0.amount }
            }
        }
        public func addPoint(amount: Decimal) {
            let new = UtilityDatapoint(amount, index: .max, parent: self);
            modelContext?.insert(new);
            
            let max = self._points?.map { $0.id }.max() ?? 0;
            new.id = max;
            if self._points != nil {
                self._points!.append(new);
            }
            else {
                self._points = [new];
            }
        }
        
        /// The previously calculated next due date, if the hash is deemed to match.
        @Transient
        private var _nextDueDate: Date? = nil;
        /// A hash of the start date, end date, and period. This is used to determine if the next due date is still valid.
        @Transient
        private var _oldHash: Int = 0;
        public var nextDueDate: Date? {
            var hasher = Hasher()
            hasher.combine(startDate)
            hasher.combine(endDate)
            hasher.combine(period)
            let computedHash = hasher.finalize()
            let lastHash = _oldHash
            _oldHash = computedHash
            
            if let nextDueDate = _nextDueDate, computedHash == lastHash {
                return nextDueDate
            }
            else {
                let result = self.computeNextDueDate()
                _nextDueDate = result;
                return result;
            }
        }
        
        /// The period as a raw value
        private var rawPeriod: Int = 0;
        
        public var amount: Decimal {
            guard let points = _points else {
                return .nan
            }
            
            return points.count == 0 ? Decimal() : points.reduce(0.0, { $0 + $1.amount } ) / Decimal(points.count)
        }
        @Transient
        public let kind: BillsKind = BillsKind.utility
        public var period: TimePeriods {
            get { TimePeriods(rawValue: rawPeriod)! }
            set { rawPeriod = newValue.rawValue }
        }
        
        public func makeSnapshot() -> UtilitySnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> UtilitySnapshot {
            .init()
        }
        
        private static func updateLists<S1, S2>(oldList: S1, newList: S2, offset: Int = 0) where S1: Sequence, S1.Element == UtilityDatapoint, S2: Sequence, S2.Element == UtilityEntryRow<CurrencyValue> {
            for (old, new) in zip(oldList, newList.enumerated()) {
                old.id = new.offset + offset
                old.amount = new.element.amount.rawValue
            }
        }
        public func update(_ from: UtilitySnapshot, unique: UniqueEngine) async throws(UniqueFailureError<BillBaseID>) {
            try await self.updateFromBase(snap: from, unique: unique)
            
            let oldPoints = self._points ?? [];
            let newPoints = from.points;
            
            // The point here is to use as many old instances as possible, while integrating the changes from the incoming elements.
            // The order is taken from the snapshot, so the same amounts in order will be placed back into the utility.
            
            if newPoints.count == oldPoints.count {
                Self.updateLists(oldList: oldPoints, newList: newPoints)
            }
            else if newPoints.count > oldPoints.count {
                //First, update the elements in the first array, and then create new elements. Join the two lists after adding the newly created.
                let matchedPoints = newPoints[0..<oldPoints.count];
                Self.updateLists(oldList: oldPoints, newList: matchedPoints)
                
                let newInstances = newPoints[oldPoints.count...].enumerated().map { UtilityDatapoint($0.element.amount.rawValue, index: $0.offset + oldPoints.count ) };
            
                for instance in newInstances {
                    modelContext?.insert(instance)
                }
                
                let allPoints = oldPoints + newInstances;
                self._points = allPoints;
            }
            else { //less
                // First grab the instances from the old points that match the count, and then remove the other instances.
                let keeping = Array(oldPoints[..<newPoints.count]); //Being stored back so we need it in array format
                let deleting = oldPoints[newPoints.count...];
                
                Self.updateLists(oldList: keeping, newList: newPoints)
                self._points = keeping;
                
                for delete in deleting {
                    modelContext?.delete(delete)
                }
            }
        }
        
        /// Example utilities that can be used to show UI filler.
        @MainActor
        public static var exampleUtility: [Utility] { [
            .init(
                "Gas",
                amounts: [
                    25,
                    23,
                    28,
                    27
                ],
                company: "TECO",
                location: "The Retreat",
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            ),
            .init(
                "Electric",
                amounts: [
                    30,
                    31,
                    35,
                    32
                ],
                company: "Lakeland Eletric",
                location: "The Retreat",
                start: Date.fromParts(2025, 1, 17)!,
                end: nil
            ),
            .init(
                "Water",
                amounts: [
                    10,
                    12,
                    14,
                    15
                ],
                company: "The Retreat",
                location: "The Retreat",
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            )
        ];
        }
    }
}

public typealias Utility = EdmundModelsV1.Utility

@Observable
public class UtilityEntryRow<T> : Identifiable {
    public init(amount: T, date: Date?, id: UUID = UUID()) {
        self.amount = amount
        self.date = date
        self.id = id
    }
    
    public let amount: T;
    public var date: Date?;
    public let id: UUID;
}
extension UtilityEntryRow : Hashable, Equatable where T: Hashable, T: Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
        hasher.combine(id)
    }
    
    public static func ==(lhs: UtilityEntryRow<T>, rhs: UtilityEntryRow<T>) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date && lhs.id == rhs.id
    }
}

/// The snapshot class used for `Utility`.
@Observable
public final class UtilitySnapshot : BillBaseSnapshot, ElementSnapshot {
    public override init() {
        self.points = [];
        
        super.init()
    }
    public init(_ from: Utility) {
        var walker = TimePeriodWalker(start: from.startDate, end: from.endDate, period: from.period, calendar: .current)
        self.points = from.points.map {
            UtilityEntryRow(
                amount: .init(rawValue: $0),
                date: walker.step()
            )
        };
        
        super.init(from)
    }
    
    /// The associated children to this instance
    public var points: [UtilityEntryRow<CurrencyValue>];
    
    /// The total amount that this utility snapshot contains, based on `children`.
    public var amount: Decimal {
        if points.isEmpty {
            return Decimal()
        }
        else {
            return points.reduce(Decimal(), { $0 + $1.amount.rawValue } ) / Decimal(points.count)
        }
    }
    
    public override func validate(unique: UniqueEngine) async -> ValidationFailure? {
        if let topResult = await super.validate(unique: unique) {
            return topResult;
        }
        
        for child in self.points {
            guard child.amount >= 0 else {
                return .negativeAmount
            }
        }
        
        return nil
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(points)
        
        super.hash(into: &hasher)
    }
    public static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        (lhs as BillBaseSnapshot) == (rhs as BillBaseSnapshot) && lhs.points == rhs.points
    }
}
