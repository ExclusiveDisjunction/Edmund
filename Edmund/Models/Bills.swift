//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import SwiftUI
import Foundation

public enum BillsKind : Int, Filterable, Equatable {
    public typealias On = Bill
    
    case subscription = 0
    case bill = 1
    case utility = 2
    
    public var id: Self { self }
    
    public var name: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription"
            case .bill: "Bill"
            case .utility: "Utility"
        }
    }
    public var pluralName: LocalizedStringKey {
        switch self {
            case .subscription: "Subscriptions"
            case .bill: "Bills"
            case .utility: "Utilities"
        }
    }
    
    public func accepts(_ val: Bill) -> Bool {
        val.kind == self
    }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public static func >(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
}
public enum BillsSort : Sortable {
    public typealias On = Bill;
    
    case name, amount, kind
    
    public var id: Self { self }
    public var toString: String {
        switch self {
            case .name: String("Name")
            case .amount: String("Amount")
            case .kind: String("Kind")
        }
    }
    public var ascendingQuestion: String {
        switch self {
            case .name: String("Alphabetical")
            case .amount: String("High to Low")
            case .kind: String("Subscription to Utility")
        }
    }
    
    public func compare(_ lhs: Bill, _ rhs: Bill, _ ascending: Bool) -> Bool {
        switch self {
            case .name: ascending ? lhs.name < rhs.name : lhs.name > rhs.name
            case .amount: ascending ? lhs.amount > rhs.amount : lhs.amount < rhs.amount
            case .kind: ascending ? lhs.kind < rhs.kind : lhs.kind > rhs.kind
        }
    }
}

public enum LongDuration : Equatable, Hashable {
    case years(Int), months(Int), weeks(Int)
    
    public var asDateComponents: DateComponents {
        switch self {
            case .years(let year): DateComponents(year: year)
            case .months(let month): DateComponents(month: month)
            case .weeks(let weeks): DateComponents(day: weeks * 7)
        }
    }
    
    public static func *(lhs: LongDuration, rhs: Int) -> LongDuration {
        switch lhs {
            case .years(let years): .years(years * rhs)
            case .months(let months): .months(months * rhs)
            case .weeks(let weeks): .weeks(weeks * rhs)
        }
    }
    
    public func adding(to date: Date, calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: asDateComponents, to: date)
    }
}

public enum BillsPeriod: Int, CaseIterable, Identifiable, Equatable {
    case weekly = 0
    case biWeekly = 1
    case monthly = 2
    case biMonthly = 3
    case quarterly = 4
    case semiAnually = 5
    case anually = 6
    
    private var index: Int {
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
    private static var daysTable: [Float] = [
        7.0,
        14.0,
        30.42,
        60.83,
        91.25,
        182.5,

    ]
    
    public var perName: LocalizedStringKey {
        switch self {
            case .weekly:      "Week"
            case .biWeekly:    "Two Weeks"
            case .monthly:     "Month"
            case .biMonthly:   "Two Months"
            case .quarterly:   "Quarter"
            case .semiAnually: "Half Year"
            case .anually:     "Year"
        }
    }
    public var name: LocalizedStringKey {
        switch self{
            case .weekly:       "Weekly"
            case .biWeekly:     "Bi-Weekly"
            case .monthly:      "Monthly"
            case .biMonthly:    "Bi-Monthly"
            case .quarterly:    "Quarterly"
            case .semiAnually:  "Semi-Anually"
            case .anually:      "Anually"
        }
    }
    
    public func conversionFactor(_ to: BillsPeriod) -> Decimal {
        let i = self.index, j = to.index
        
        return BillsPeriod.compTable[i][j]
    }
    public var asDuration: LongDuration {
        switch self {
            case .weekly: .weeks(1)
            case .biWeekly: .weeks(2)
            case .monthly: .months(1)
            case .biMonthly: .months(2)
            case .quarterly: .months(3)
            case .semiAnually: .months(6)
            case .anually: .years(1)
        }
    }
    public var daysInPeriod: Float {
        Self.daysTable[self.index]
    }
    
    public var id: Self { self }
}

@Model
public final class Bill : Identifiable, Queryable {
    public typealias SortType = BillsSort
    public typealias FilterType = BillsKind
    
    public convenience init(sub: String, amount: Decimal, start: Date, end: Date? = nil, period: BillsPeriod = .monthly) {
        self.init(name: sub, kind: .subscription, amount: amount, child: nil, start: start, end: end, period: period)
    }
    public convenience init(bill: String, amount: Decimal, start: Date, end: Date? = nil, period: BillsPeriod = .monthly) {
        self.init(name: bill, kind: .bill, amount: amount, child: nil, start: start, end: end, period: period)
    }
    public convenience init(utility: String, amounts: [UtilityEntry], start: Date, end: Date? = nil, period: BillsPeriod = .monthly) {
        self.init(name: utility, kind: .utility, amount: 0, child: .init(nil, amounts: amounts), start: start, end: end, period: period)
        self.child?.parent = self
    }
    public init(name: String, kind: BillsKind, amount: Decimal, child: UtilityBridge?, start: Date, end: Date?, period: BillsPeriod) {
        self.name = name
        self.rawKind = kind.rawValue
        self.rawAmount = amount
        self.child = child
        self.startDate = start
        self.endDate = end
        self.rawPeriod = period.rawValue
        self.id = UUID()
    }
    
    public var id: UUID
    @Attribute(.unique) public var name: String
    public var startDate: Date;
    public var endDate: Date?
    private var rawAmount: Decimal;
    private var rawKind: Int;
    private var rawPeriod: Int;
    @Relationship(deleteRule: .cascade, inverse: \UtilityBridge.parent) public var child: UtilityBridge?
    
    public var amount: Decimal {
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
    public var kind: BillsKind {
        if child != nil {
            .utility
        }
        else {
            BillsKind(rawValue: rawKind)!
        }
    }
    
    public var period: BillsPeriod {
        get {
            BillsPeriod(rawValue: self.rawPeriod)!
        }
        set {
            self.rawPeriod = newValue.rawValue
        }
    }
    public var daysSinceStart: Int {
        let components = Calendar.current.dateComponents([.day], from: self.startDate, to: Date.now)
        return components.day ?? 0
    }
    public var periodsSinceStart: Int {
        let days = Float(daysSinceStart);
        let periodDays = self.period.daysInPeriod;
        
        let rawPeriods = days / periodDays
        return Int(rawPeriods.rounded(.towardZero))
    }
    public var nextBillDate: Date? {
        let duration = self.period.asDuration * periodsSinceStart;
        let nextDate = Calendar.current.date(byAdding: duration.asDateComponents, to: self.startDate);
        if let nextDate = nextDate, let endDate = self.endDate {
            if nextDate > endDate {
                return nil
            }
            else {
                return nextDate
            }
        }
        else {
            return nextDate
        }
    }
    public var isExpired: Bool {
        if let endDate = endDate {
            Date.now > endDate
        }
        else {
            false
        }
    }

    public func pricePer(_ period: BillsPeriod) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    
#if DEBUG
    static let exampleExpiredBills: [Bill] = {
        [
            .init(sub: "Bitwarden", amount: 9.99, start: Date.fromParts(2024, 6, 6)!, end: Date.fromParts(2025, 3, 1)!, period: .anually),
            .init(sub: "Spotify", amount: 16.99, start: Date.fromParts(2020, 1, 17)!, end: Date.fromParts(2025, 3, 2)!, period: .monthly)
          ]
    }()
    static let exampleSubscriptions: [Bill] = {
        [
            .init(sub: "Apple Music",     amount: 5.99, start: Date.fromParts(2025, 3, 2)!, end: nil),
            .init(sub: "iCloud",          amount: 2.99, start: Date.fromParts(2025, 5, 15)!, end: nil),
            .init(sub: "YouTube Premium", amount: 9.99, start: Date.fromParts(2024, 11, 7)!, end: nil)
        ]
    }()
    static let exampleActualBills: [Bill] = {
        [
            .init(bill: "Student Loan",  amount: 56,  start: Date.fromParts(2025, 3, 2)!,  end: nil),
            .init(bill: "Car Insurance", amount: 899, start: Date.fromParts(2024, 7, 25)!, end: nil, period: .semiAnually),
            .init(bill: "Internet",      amount: 60,  start: Date.fromParts(2024, 7, 25)!, end: nil)
        ]
    }()
    static let exampleUtility: [Bill] = {
        [
            .init(
                utility: "Gas",
                amounts: [
                    .init(Date.fromParts(2025, 1, 25)!, 25),
                    .init(Date.fromParts(2025, 2, 25)!, 23),
                    .init(Date.fromParts(2025, 3, 25)!, 28),
                    .init(Date.fromParts(2025, 4, 25)!, 27)],
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            ),
            .init(
                utility: "Electric",
                amounts: [
                    .init(Date.fromParts(2025, 1, 17)!, 30),
                    .init(Date.fromParts(2025, 2, 17)!, 31),
                    .init(Date.fromParts(2025, 3, 17)!, 35),
                    .init(Date.fromParts(2025, 4, 17)!, 32)],
                start: Date.fromParts(2025, 1, 17)!,
                end: nil
            ),
            .init(
                utility: "Water",
                amounts: [
                    .init(Date.fromParts(2025, 1, 2)!, 10),
                    .init(Date.fromParts(2025, 2, 2)!, 12),
                    .init(Date.fromParts(2025, 3, 2)!, 14),
                    .init(Date.fromParts(2025, 4, 2)!, 15)],
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            )
        ]
    }()
    
    static let exampleBills: [Bill] = {
        var result: [Bill] = [];
        result.append(contentsOf: exampleExpiredBills)
        result.append(contentsOf: exampleSubscriptions)
        result.append(contentsOf: exampleActualBills)
        result.append(contentsOf: exampleUtility)
        
        return result
    }()
#endif
}

extension Date {
    static func fromParts(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }
}

@Model
public class UtilityEntry: Identifiable {
    public init(_ date: Date, _ amount: Decimal) {
        self.date = date
        self.amount = amount
    }
    
    public var id = UUID()
    public var date: Date;
    public var amount: Decimal;
    @Relationship public var parent: UtilityBridge?;
}

@Model
public final class UtilityBridge : Identifiable {
    public init(_ parent: Bill?, amounts: [UtilityEntry] = [], id: UUID = UUID()) {
        self.id = id
        self.parent = parent
        self.amounts = amounts
    }
    
    public var id: UUID;
    @Relationship public var parent: Bill?
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent) public var amounts: [UtilityEntry]
    
    public var averagePrice: Decimal {
        amounts.reduce(Decimal(0), { $0 + $1.amount} ) / Decimal(amounts.count)
    }
}
