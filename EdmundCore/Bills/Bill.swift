//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import SwiftUI
import Foundation

/// A data set pertaining to a same-amount periodic charge.
@Model
public final class Bill : BillBase, SnapshotableElement, UniqueElement {
    public typealias Snapshot = BillSnapshot
    
    /// Creates the bill based on a specific kind.
    public convenience init(kind: StrictBillsKind) {
        self.init(name: "", kind: kind, amount: 0, company: "", start: Date.now)
    }
    /// Creates a subscription kind bill, with specified values.
    public convenience init(sub: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.init(name: sub, kind: .subscription,  amount: amount, company: company, location: location, start: start, end: end, period: period)
    }
    /// Creates a bill kind, with specified values
    public convenience init(bill: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.init(name: bill, kind: .bill, amount: amount, company: company, location: location, start: start, end: end, period: period)
    }
    /// Creates a bill while filling in all fields.
    public init(name: String, kind: StrictBillsKind, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.name = name
        self.amount = amount
        self.startDate = start
        self.endDate = end
        self.company = company
        self.location = location
        self._kind = kind.rawValue
        self._period = period.rawValue
    }
    
    public static let objId: ObjectIdentifier = .init((any BillBase).self)
    
    public var id: BillBaseID {
        .init(name: name, company: company, location: location)
    }
    public var name: String = "";
    public var amount: Decimal = 0.0;
    public var startDate: Date = Date.now;
    public var endDate: Date? = nil;
    public var company: String = "";
    public var location: String? = nil;
    public var notes: String = "";
    public var autoPay: Bool = true;
    
    @Transient
    private var _nextDueDate: Date? = nil;
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
    
    /// The internal raw value used to store the kind.
    public private(set) var _kind: StrictBillsKind.RawValue;
    /// The internall raw value used to store the period.
    private var _period: TimePeriods.RawValue;
    
    public var trueKind: StrictBillsKind {
        get {
            StrictBillsKind(rawValue: _kind) ?? .bill
        }
        set {
            self._kind = newValue.rawValue
        }
    }
    public var kind: BillsKind {
        get {
            switch self.trueKind {
                case .subscription: .subscription
                case .bill: .bill
            }
        }
    }
    public var period: TimePeriods {
        get {
            TimePeriods(rawValue: _period) ?? .monthly
        }
        set {
            self._period = newValue.rawValue
        }
    }
    
    public func makeSnapshot() -> BillSnapshot {
        BillSnapshot(self)
    }
    public static func makeBlankSnapshot() -> BillSnapshot {
        BillSnapshot()
    }
    public func update(_ from: BillSnapshot, unique: UniqueEngine) async throws(UniqueFailureError<BillBaseID>) {
        try await self.updateFromBase(snap: from, unique: unique)
        
        self.amount   = from.amount.rawValue
        self.trueKind = from.kind
    }
    
    /// A list of filler data for bills that have already expired.
    @MainActor
    public static let exampleExpiredBills: [Bill] = [
        .init(sub: "Bitwarden Premium",      amount: 9.99,  company: "Bitwarden", start: Date.fromParts(2024, 6, 6)!,  end: Date.fromParts(2025, 3, 1)!, period: .anually),
        .init(sub: "Spotify Premium Family", amount: 16.99, company: "Spotify",   start: Date.fromParts(2020, 1, 17)!, end: Date.fromParts(2025, 3, 2)!, period: .monthly)
    ]
    /// Examples of subscriptions that can be used on the UI.
    @MainActor
    public static let exampleSubscriptions: [Bill] = [
        .init(sub: "Apple Music",     amount: 5.99, company: "Apple",   start: Date.fromParts(2025, 3, 2)!,  end: nil),
        .init(sub: "iCloud+",         amount: 2.99, company: "Apple",   start: Date.fromParts(2025, 5, 15)!, end: nil),
        .init(sub: "YouTube Premium", amount: 9.99, company: "YouTube", start: Date.fromParts(2024, 11, 7)!, end: nil)
    ]
    /// Examples of bill kind bills that can be used on UI.
    @MainActor
    public static let exampleActualBills: [Bill] = [
        .init(bill: "Student Loan",  amount: 56,  company: "FAFSA",       start: Date.fromParts(2025, 3, 2)!,  end: nil),
        .init(bill: "Car Insurance", amount: 899, company: "The General", start: Date.fromParts(2024, 7, 25)!, end: nil, period: .semiAnually),
        .init(bill: "Internet",      amount: 60,  company: "Spectrum",    start: Date.fromParts(2024, 7, 25)!, end: nil)
    ]
    
    /// A collection of all bills used to show filler UI data.
    @MainActor
    public static let exampleBills: [Bill] = exampleExpiredBills + exampleSubscriptions + exampleActualBills
}

/// The snapshot type for `Bill`.
@Observable
public final class BillSnapshot : BillBaseSnapshot, ElementSnapshot {
    public override init() {
        self.amount = .init()
        self.kind = .bill
        
        super.init()
    }
    public init(_ from: Bill) {
        self.amount = .init(rawValue: from.amount)
        self.kind = from.trueKind
        
        super.init(from)
    }
    
    /// The cost of the bill/subscription
    public var amount: CurrencyValue;
    /// The bill's kind.
    public var kind: StrictBillsKind;
    
    public override func validate(unique: UniqueEngine) async -> ValidationFailure? {
        if let topResult = await super.validate(unique: unique) {
            return topResult
        }
        
        if amount.rawValue < 0 { return .negativeAmount }
        
        return nil
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(kind)
        super.hash(into: &hasher)
    }
    
    public static func ==(lhs: BillSnapshot, rhs: BillSnapshot) -> Bool {
        (lhs as BillBaseSnapshot) == (rhs as BillBaseSnapshot) && lhs.amount == rhs.amount && lhs.kind == rhs.kind
    }
}

