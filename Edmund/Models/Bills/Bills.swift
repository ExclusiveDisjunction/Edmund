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
final class Bill : BillBase, EditableElement, InspectableElement {
    typealias EditView = BillEdit
    typealias InspectorView = BillInspect
    typealias Snapshot = BillSnapshot
    
    convenience init(sub: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.init(name: sub, kind: .subscription,  amount: amount, company: company, location: location, start: start, end: end, period: period, id: id)
    }
    convenience init(bill: String, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.init(name: bill, kind: .bill, amount: amount, company: company, location: location, start: start, end: end, period: period, id: id)
    }
    init(name: String, kind: BillsKind, amount: Decimal, company: String, location: String? = nil, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.amount = amount
        self.startDate = start
        self.endDate = end
        self.company = company
        self.location = location
        self.rawKind = kind.rawValue
        self.rawPeriod = period.rawValue
    }
    
    var id: UUID
    @Attribute(.unique) var name: String;
    var amount: Decimal;
    var startDate: Date;
    var endDate: Date?;
    var company: String;
    var location: String?;
    var notes: String = String();
    
    internal var rawKind: Int;
    private var rawPeriod: Int;
    
    var kind: BillsKind {
        get {
            BillsKind(rawValue: rawKind)!
        }
        set {
            guard newValue != .utility else { return }
            
            self.rawKind = newValue.rawValue
        }
    }
    var period: BillsPeriod {
        get {
            BillsPeriod(rawValue: rawPeriod)!
        }
        set {
            self.rawPeriod = newValue.rawValue
        }
    }
    
#if DEBUG
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
#endif
}

@Observable
final class BillSnapshot : BillBaseSnapshotKind {
    init(_ from: Bill) {
        self.id = UUID();
        self.base = .init(from)
        self.amount = from.amount
        self.kind = from.kind
    }
    
    var id: UUID;
    var base: BillBaseSnapshot;
    var amount: Decimal;
    var kind: BillsKind;
    
    func validate() -> Bool {
        let top_result = self.base.isValid
        
        if self.amount < 0 {
            self.base.errors.insert(.amount)
        }
        
        return self.amount >= 0 && top_result
    }
    
    func apply(_ to: Bill, context: ModelContext) {
        base.apply(to)
        to.amount = amount
        to.kind = kind
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
        hasher.combine(amount)
        hasher.combine(kind)
    }
    
    static func ==(lhs: BillSnapshot, rhs: BillSnapshot) -> Bool {
        lhs.base == rhs.base && lhs.amount == rhs.amount && lhs.kind == rhs.kind
    }
}

