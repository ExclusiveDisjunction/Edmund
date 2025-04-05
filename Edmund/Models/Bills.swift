//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import Foundation

enum BillsKind : String, Filterable {
    typealias On = Bill
    
    case subscription = "Subscription"
    case bill = "Bill"
    case utility = "Utility"
    
    var id: Self { self }
    
    var toString: String {
        self.rawValue
    }
    var toStringPlural: String {
        switch self {
            case .subscription: "Subscriptions"
            case .bill: "Bills"
            case .utility: "Utilities"
        }
    }
    
    func accepts(_ val: Bill) -> Bool {
        val.kind == self
    }
}
enum BillsSort : String, Sortable {
    typealias On = Bill;
    
    case name = "Name", amount = "Amount"
    
    var id: Self { self }
    var toString: String {
        self.rawValue
    }
    var ascendingQuestion: String {
        switch self {
            case .name: "Alphabetical"
            case .amount: "Low to High"
        }
    }
    
    func compare(_ lhs: Bill, _ rhs: Bill, _ ascending: Bool) -> Bool {
        switch self {
            case .name: ascending ? lhs.name < rhs.name : lhs.name > rhs.name
            case .amount: ascending ? lhs.amount < rhs.amount : lhs.amount > rhs.amount
        }
    }
}

enum BillsPeriod: String, CaseIterable, Identifiable, Equatable {
    case weekly =      "Weekly"
    case biWeekly =    "Bi-Weekly"
    case monthly =     "Monthly"
    case biMonthly =   "Bi-Monthly"
    case quarterly =   "Quarterly"
    case semiAnually = "Semi-Anually"
    case anually =     "Anually"
    
    var index: Int {
        switch self {
            case .weekly: 0
            case .biWeekly: 1
            case .monthly: 2
            case .biMonthly: 3
            case .quarterly: 4
            case .semiAnually: 5
            case .anually: 6
        }
    }
    private static var compTable: [[Decimal]] = {
        return [
        //   Week      Bi-Week   Month     Bi-Month  Quarter  HYear    Year
            [1.0     , 2.0     , 4.0     , 8.0     , 12.0   , 26.0   , 52.0].map { Decimal($0) },
            [1.0/2.0 , 1.0     , 2.0     , 4.0     , 6.0    , 12.0   , 26.0].map { Decimal($0) },
            [1.0/4.0 , 1.0/2.0 , 1.0     , 2.0     , 4.0    , 6.0    , 12.0].map { Decimal($0) },
            [1.0/8.0 , 1.0/4.0 , 1.0/2.0 , 1.0     , 2.0    , 4.0    , 6.0 ].map { Decimal($0) },
            [1.0/12.0, 1.0/6.0 , 1.0/4.0 , 1.0/2.0 , 1.0    , 2.0    , 4.0 ].map { Decimal($0) },
            [1.0/26.0, 1.0/12.0, 1.0/6.0 , 1.0/4.0 , 1.0/2.0, 1.0    , 2.0 ].map { Decimal($0) },
            [1.0/52.0, 1.0/26.0, 1.0/12.0, 1.0/16.0, 1.0/4.0, 1.0/2.0, 1.0 ].map { Decimal($0) }
        ]
    }()
    
    var perName: String {
        switch self {
            case .weekly: String(localized: "Week")
            case .biWeekly: String(localized: "Two Weeks")
            case .monthly: String(localized: "Month")
            case .biMonthly: String(localized: "Two Months")
            case .quarterly: String(localized: "Quarter")
            case .semiAnually: String(localized: "Half Year")
            case .anually: String(localized: "Year")
        }
    }
    
    func conversionFactor(_ to: BillsPeriod) -> Decimal {
        let i = self.index, j = to.index
        
        return BillsPeriod.compTable[i][j]
    }
    
    var id: Self { self }
}

@Model
final class Bill : Identifiable, Queryable {
    typealias SortType = BillsSort
    typealias FilterType = BillsKind
    
    convenience init(sub: String, amount: Decimal, period: BillsPeriod = .monthly) {
        self.init(name: sub, kind: .subscription, amount: amount, child: nil, period: period)
    }
    convenience init(bill: String, amount: Decimal, period: BillsPeriod = .monthly) {
        self.init(name: bill, kind: .bill, amount: amount, child: nil, period: period)
    }
    convenience init(utility: String, amounts: [UtilityEntry], period: BillsPeriod = .monthly) {
        self.init(name: utility, kind: .utility, amount: 0, child: .init(nil, amounts: amounts), period: period)
        self.child?.parent = self
    }
    init(name: String, kind: BillsKind, amount: Decimal, child: UtilityBridge?, period: BillsPeriod) {
        self.name = name
        self.rawKind = kind.rawValue
        self.rawAmount = amount
        self.child = child
        self.rawPeriod = period.rawValue
        self.id = UUID()
    }
    
    var id: UUID
    @Attribute(.unique) var name: String
    private var rawAmount: Decimal;
    private var rawKind: String;
    private var rawPeriod: String;
    @Relationship(deleteRule: .cascade, inverse: \UtilityBridge.parent) var child: UtilityBridge?
    
    var amount: Decimal {
        get {
            if let child = child {
                child.averagePrice
            }
            else {
                self.rawAmount
            }
        }
        set {
            self.rawAmount = newValue
        }
    }
    var kind: BillsKind {
        if child != nil {
            .utility
        }
        else {
            BillsKind(rawValue: rawKind)!
        }
    }
    
    var period: BillsPeriod {
        get {
            BillsPeriod(rawValue: self.rawPeriod)!
        }
        set {
            self.rawPeriod = newValue.rawValue
        }
    }

    func pricePer(_ period: BillsPeriod) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    
    static let exampleBills: [Bill] = {
        [
            .init(sub: "Apple Music", amount: 5.99),
            .init(sub: "iCloud", amount: 2.99),
            .init(sub: "YouTube Premium", amount: 9.99),
            .init(bill: "Student Loan", amount: 56),
            .init(bill: "Car Insurance", amount: 899, period: .semiAnually),
            .init(utility: "Gas", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 25))!, 25),
                                           .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 25))!, 23),
                                           .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 25))!, 28),
                                           .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 25))!, 27)]),
            .init(utility: "Electric", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 17))!, 30),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 17))!, 31),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 17))!, 38),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 17))!, 36)]),
            .init(utility: "Internet", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 14))!, 34),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 14))!, 25),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 14))!, 35),
                                                .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 14))!, 35)]),
            .init(utility: "Water", amounts: [.init(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 2))!, 10),
                                             .init(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 2))!, 12),
                                             .init(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 2))!, 14),
                                             .init(Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 2))!, 15)])
        ]
    }()
}

@Model
class UtilityEntry: Identifiable {
    init(_ date: Date, _ amount: Decimal) {
        self.date = date
        self.amount = amount
    }
    
    var id = UUID()
    var date: Date;
    var amount: Decimal;
    @Relationship var parent: UtilityBridge?;
}

@Model
final class UtilityBridge : Identifiable {
    init(_ parent: Bill?, amounts: [UtilityEntry] = [], id: UUID = UUID()) {
        self.id = id
        self.parent = parent
        self.amounts = amounts
    }
    
    var id: UUID;
    @Relationship var parent: Bill?
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent) var amounts: [UtilityEntry]
    
    var averagePrice: Decimal {
        amounts.reduce(Decimal(0), { $0 + $1.amount} ) / Decimal(amounts.count)
    }
}
