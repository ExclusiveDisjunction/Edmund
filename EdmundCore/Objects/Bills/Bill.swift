//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import SwiftUI
import Foundation

@Model
public final class Bill : BillBase, NamedEditableElement, NamedInspectableElement {
    public typealias EditView = BillEdit
    public typealias InspectorView = BillInspect
    public typealias Snapshot = BillSnapshot
    
    /// Creates the bill based on a specific kind.
    public convenience init(kind: BillsKind) {
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
    /// Note that it is undefined behavior if kind is `.utility`.
    public init(name: String, kind: BillsKind, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.amount = amount
        self._kind = kind.rawValue
        
        super.init(name: name, startDate: start, endDate: end, period: period, company: company, location: location)
    }
    
    public override var amount: Decimal = 0.0;
    public override var kind: BillsKind {
        get { BillsKind(rawValue: _kind)! }
        set { _kind = newValue.rawValue }
    }
    
    private var _kind: Int = BillsKind.bill.rawValue

    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Bill",
            plural:   "Bills",
            inspect:  "Inspect Bill",
            edit:     "Edit Bill",
            add:      "Add Bill"
        )
    }
    
    /// A list of filler data for bills that have already expired.
    public static let exampleExpiredBills: [Bill] = {
        [
            .init(sub: "Bitwarden Premium",      amount: 9.99,  company: "Bitwarden", start: Date.fromParts(2024, 6, 6)!,  end: Date.fromParts(2025, 3, 1)!, period: .anually),
            .init(sub: "Spotify Premium Family", amount: 16.99, company: "Spotify",   start: Date.fromParts(2020, 1, 17)!, end: Date.fromParts(2025, 3, 2)!, period: .monthly)
        ]
    }()
    /// Examples of subscriptions that can be used on the UI.
    public static let exampleSubscriptions: [Bill] = {
        [
            .init(sub: "Apple Music",     amount: 5.99, company: "Apple",   start: Date.fromParts(2025, 3, 2)!,  end: nil),
            .init(sub: "iCloud+",         amount: 2.99, company: "Apple",   start: Date.fromParts(2025, 5, 15)!, end: nil),
            .init(sub: "YouTube Premium", amount: 9.99, company: "YouTube", start: Date.fromParts(2024, 11, 7)!, end: nil)
        ]
    }()
    /// Examples of bill kind bills that can be used on UI.
    public static let exampleActualBills: [Bill] = {
        [
            .init(bill: "Student Loan",  amount: 56,  company: "FAFSA",       start: Date.fromParts(2025, 3, 2)!,  end: nil),
            .init(bill: "Car Insurance", amount: 899, company: "The General", start: Date.fromParts(2024, 7, 25)!, end: nil, period: .semiAnually),
            .init(bill: "Internet",      amount: 60,  company: "Spectrum",    start: Date.fromParts(2024, 7, 25)!, end: nil)
        ]
    }()
    
    /// A collection of all bills used to show filler UI data.
    public static let exampleNormalBills: [Bill] = {
        exampleExpiredBills + exampleSubscriptions + exampleActualBills
    }()
}

/// The snapshot type for `Bill`.
@Observable
public final class BillSnapshot : BillBaseSnapshot, ElementSnapshot {
    public init(_ from: Bill) {
        self.amount = .init(rawValue: from.amount)
        self.kind = from.kind
        
        super.init(from)
    }
    
    /// The cost of the bill/subscription
    public var amount: CurrencyValue;
    /// The kind. This will be constrained to be either `.subscription` or `.bill`.
    public var kind: BillsKind;
    
    public override func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var topResult = super.validate(unique: unique);
        
        if amount.rawValue < 0 { topResult.append(.negativeAmount("Amount")) }
        if kind == .utility { topResult.append(.invalidInput("Kind")) }
        
        return topResult
    }
    public func apply(_ to: Bill, context: ModelContext, unique: UniqueEngine) throws (UniqueFailueError<BillBaseID>) {
        try super.apply(to: to, unique: unique)
        
        to.amount = amount.rawValue
        to.kind = kind
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

