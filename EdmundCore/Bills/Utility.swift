//
//  Utilities.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;
import Foundation;

extension Utility : BillBase, SnapshotableElement, UniqueElement, IsolatedDefaultableElement, NamedElement {
    public typealias Snapshot = UtilitySnapshot
    
    /// Creates the utility with blank values.
    public convenience init() {
        self.init("", amounts: [], company: "", start: Date.now)
    }
    
    public static let objId: ObjectIdentifier = .init((any BillBase).self)
    
    public var uID: BillBaseID {
        .init(name: name, company: company, location: location)
    }
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
    
    public var amount: Decimal {
        let reduced = history.compactMap { $0.amount };
        return reduced.count == 0 ? Decimal() : (reduced.reduce(0.0, +) / Decimal(reduced.count))
    }
    public var period: TimePeriods {
        get { TimePeriods(rawValue: _period) ?? .monthly }
        set { _period = newValue.rawValue }
    }
    
    public func makeSnapshot() -> UtilitySnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> UtilitySnapshot {
        .init()
    }
    public func update(_ from: UtilitySnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        try await self.updateFromBase(snap: from, unique: unique)
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

/// The snapshot class used for `Utility`.
@Observable
public final class UtilitySnapshot : BillBaseSnapshot, ElementSnapshot {
    public override init() {
        super.init()
    }
    public init(_ from: Utility) {
        super.init(from)
    }
    
    /// The total amount that this utility snapshot contains, based on `children`.
    public var amount: Decimal {
        let reduced = history.compactMap { $0.trueAmount?.rawValue };
        return reduced.count == 0 ? Decimal() : (reduced.reduce(0.0, +) / Decimal(reduced.count))
    }
    
    public override func validate(unique: UniqueEngine) async -> ValidationFailure? {
        await super.validate(unique: unique)
    }
    
    public static func ==(lhs: UtilitySnapshot, rhs: UtilitySnapshot) -> Bool {
        (lhs as BillBaseSnapshot) == (rhs as BillBaseSnapshot)
    }
}
