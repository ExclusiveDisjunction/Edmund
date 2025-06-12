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
public final class Bill : BillBase, NamedEditableElement, NamedInspectableElement, UniqueElement {
    public typealias EditView = BillEdit
    public typealias InspectorView = BillInspect
    public typealias Snapshot = BillSnapshot
    
    public convenience init(kind: BillsKind) {
        self.init(name: "", kind: kind, amount: 0, company: "", start: Date.now)
    }
    public convenience init(sub: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.init(name: sub, kind: .subscription,  amount: amount, company: company, location: location, start: start, end: end, period: period)
    }
    public convenience init(bill: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.init(name: bill, kind: .bill, amount: amount, company: company, location: location, start: start, end: end, period: period)
    }
    public init(name: String, kind: BillsKind, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: TimePeriods = .monthly) {
        self.name = name
        self.amount = amount
        self.startDate = start
        self.endDate = end
        self.company = company
        self.location = location
        self.rawKind = kind.rawValue
        self.rawPeriod = period.rawValue
    }
    
    public var id: String {
        "\(name).\(company).\(location ?? "")"
    }
    public var name: String = "";
    public var amount: Decimal = 0.0;
    public var startDate: Date = Date.now;
    public var endDate: Date? = nil;
    public var company: String = "";
    public var location: String? = nil;
    public var notes: String = "";
    public var destination: SubAccount? = nil;
    public var autoPay: Bool = true;
    
    public var rawKind: Int = 0;
    private var rawPeriod: Int = 0;
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Bill",
            plural:   "Bills",
            inspect:  "Inspect Bill",
            edit:     "Edit Bill",
            add:      "Add Bill"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Name"), .init(name: "Company"), .init(name: "Location", optional: true) ]
    }
    
    public var kind: BillsKind {
        get {
            BillsKind(rawValue: rawKind)!
        }
        set {
            guard newValue != .utility else { return }
            
            self.rawKind = newValue.rawValue
        }
    }
    public var period: TimePeriods {
        get {
            TimePeriods(rawValue: rawPeriod)!
        }
        set {
            self.rawPeriod = newValue.rawValue
        }
    }
    
    static let exampleExpiredBills: [Bill] = {
        [
            .init(sub: "Bitwarden Premium",      amount: 9.99,  company: "Bitwarden", start: Date.fromParts(2024, 6, 6)!,  end: Date.fromParts(2025, 3, 1)!, period: .anually),
            .init(sub: "Spotify Premium Family", amount: 16.99, company: "Spotify",   start: Date.fromParts(2020, 1, 17)!, end: Date.fromParts(2025, 3, 2)!, period: .monthly)
        ]
    }()
    static let exampleSubscriptions: [Bill] = {
        [
            .init(sub: "Apple Music",     amount: 5.99, company: "Apple",   start: Date.fromParts(2025, 3, 2)!,  end: nil),
            .init(sub: "iCloud+",         amount: 2.99, company: "Apple",   start: Date.fromParts(2025, 5, 15)!, end: nil),
            .init(sub: "YouTube Premium", amount: 9.99, company: "YouTube", start: Date.fromParts(2024, 11, 7)!, end: nil)
        ]
    }()
    static let exampleActualBills: [Bill] = {
        [
            .init(bill: "Student Loan",  amount: 56,  company: "FAFSA",       start: Date.fromParts(2025, 3, 2)!,  end: nil),
            .init(bill: "Car Insurance", amount: 899, company: "The General", start: Date.fromParts(2024, 7, 25)!, end: nil, period: .semiAnually),
            .init(bill: "Internet",      amount: 60,  company: "Spectrum",    start: Date.fromParts(2024, 7, 25)!, end: nil)
        ]
    }()
    
    static let exampleBills: [Bill] = {
        var result: [Bill] = [];
        result.append(contentsOf: exampleExpiredBills)
        result.append(contentsOf: exampleSubscriptions)
        result.append(contentsOf: exampleActualBills)
        
        return result
    }()
}

@Observable
public final class BillSnapshot : BillBaseSnapshotKind {
    public init(_ from: Bill) {
        self.id = UUID();
        self.base = .init(from)
        self.amount = .init(rawValue: from.amount)
        self.kind = from.kind
    }
    
    public var id: UUID;
    public var base: BillBaseSnapshot;
    public var amount: CurrencyValue;
    public var kind: BillsKind;
    
    public func validate() -> Bool {
        let top_result = self.base.isValid
        
        if self.amount < 0 {
            self.base.errors.insert(.amount)
        }
        
        return self.amount >= 0 && top_result
    }
    
    public func apply(_ to: Bill, context: ModelContext) {
        base.apply(to)
        to.amount = amount.rawValue
        to.kind = kind
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(amount)
        hasher.combine(kind)
    }
    
    public static func ==(lhs: BillSnapshot, rhs: BillSnapshot) -> Bool {
        lhs.base == rhs.base && lhs.amount == rhs.amount && lhs.kind == rhs.kind
    }
}

