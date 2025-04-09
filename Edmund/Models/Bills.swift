//
//  Bills.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftData
import SwiftUI
import Foundation

enum BillsKind : Int, Filterable, Equatable {
    typealias On = BillBaseWrapper
    
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
    
    public func accepts(_ val: BillBaseWrapper) -> Bool {
        val.data.kind == self
    }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    public static func >(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
}
enum BillsSort : Sortable {
    typealias On = BillBaseWrapper;
    
    case name, amount, kind
    
    var id: Self { self }
    var toString: LocalizedStringKey {
        switch self {
            case .name: "Name"
            case .amount: "Amount"
            case .kind: "Kind"
        }
    }
    var ascendingQuestion: LocalizedStringKey {
        switch self {
            case .name: "Alphabetical"
            case .amount: "High to Low"
            case .kind: "Subscription to Utility"
        }
    }
    
    func compare(_ lhs: BillBaseWrapper, _ rhs: BillBaseWrapper, _ ascending: Bool) -> Bool {
        switch self {
            case .name: ascending ? lhs.data.name < rhs.data.name : lhs.data.name > rhs.data.name
            case .amount: ascending ? lhs.data.amount > rhs.data.amount : lhs.data.amount < rhs.data.amount
            case .kind: ascending ? lhs.data.kind < rhs.data.kind : lhs.data.kind > rhs.data.kind
        }
    }
}

extension Date {
    static func fromParts(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }
}
enum LongDuration : Equatable, Hashable {
    case years(Int), months(Int), weeks(Int)
    
    var asDateComponents: DateComponents {
        switch self {
            case .years(let year): DateComponents(year: year)
            case .months(let month): DateComponents(month: month)
            case .weeks(let weeks): DateComponents(day: weeks * 7)
        }
    }
    
    static func *(lhs: LongDuration, rhs: Int) -> LongDuration {
        switch lhs {
            case .years(let years): .years(years * rhs)
            case .months(let months): .months(months * rhs)
            case .weeks(let weeks): .weeks(weeks * rhs)
        }
    }
    
    func adding(to date: Date, calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: asDateComponents, to: date)
    }
}

enum BillsPeriod: Int, CaseIterable, Identifiable, Equatable {
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
    
    var perName: LocalizedStringKey {
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
    var name: LocalizedStringKey {
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
    
    func conversionFactor(_ to: BillsPeriod) -> Decimal {
        let i = self.index, j = to.index
        
        return BillsPeriod.compTable[i][j]
    }
    var asDuration: LongDuration {
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
    var daysInPeriod: Float {
        Self.daysTable[self.index]
    }
    
    var id: Self { self }
}

protocol BillBase : Identifiable {
    var name: String { get set }
    var startDate: Date { get set }
    var endDate: Date? { get set }
    var period: BillsPeriod { get set }
    var kind: BillsKind { get }
    var amount: Decimal { get }
}
extension BillBase {
    var daysSinceStart: Int {
        let components = Calendar.current.dateComponents([.day], from: self.startDate, to: Date.now)
        return components.day ?? 0
    }
    var periodsSinceStart: Int {
        let days = Float(daysSinceStart);
        let periodDays = self.period.daysInPeriod;
        
        let rawPeriods = days / periodDays
        return Int(rawPeriods.rounded(.towardZero))
    }
    var nextBillDate: Date? {
        let duration = self.period.asDuration * (periodsSinceStart + 1);
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
    var isExpired: Bool {
        if let endDate = endDate {
            Date.now > endDate
        }
        else {
            false
        }
    }
    func pricePer(_ period: BillsPeriod) -> Decimal {
        self.amount * self.period.conversionFactor(period)
    }
    
    mutating func update(_ from: any BillBase) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.endDate
        self.period = from.period
    }
    mutating func update(_ from: BillBaseManifest) {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.endDate
        self.period = from.period
    }
}

struct BillBaseWrapper : Identifiable, Queryable {
    typealias SortType = BillsSort
    typealias FilterType = BillsKind
    
    init(_ data: any BillBase, id: UUID = UUID()) {
        self.data = data
        self.id = id 
    }
    
    var data: any BillBase;
    var id: UUID;
}

@Model
final class Bill : BillBase {
    convenience init(sub: String, amount: Decimal, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.init(name: sub, kind: .subscription, amount: amount, start: start, end: end, period: period, id: id)
    }
    convenience init(bill: String, amount: Decimal, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.init(name: bill, kind: .bill, amount: amount, start: start, end: end, period: period, id: id)
    }
    init(name: String, kind: BillsKind, amount: Decimal, start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.amount = amount
        self.startDate = start
        self.endDate = end
        self.rawKind = kind.rawValue
        self.rawPeriod = period.rawValue
    }
    
    var id: UUID
    @Attribute(.unique) var name: String;
    var amount: Decimal;
    var startDate: Date;
    var endDate: Date?;
    
    private var rawKind: Int;
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
            .init(sub: "Bitwarden", amount: 9.99,  start: Date.fromParts(2024, 6, 6)!,  end: Date.fromParts(2025, 3, 1)!, period: .anually),
            .init(sub: "Spotify",   amount: 16.99, start: Date.fromParts(2020, 1, 17)!, end: Date.fromParts(2025, 3, 2)!, period: .monthly)
        ]
    }()
    static let exampleSubscriptions: [Bill] = {
        [
            .init(sub: "Apple Music",     amount: 5.99, start: Date.fromParts(2025, 3, 2)!,  end: nil),
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
    
    static let exampleBills: [Bill] = {
        var result: [Bill] = [];
        result.append(contentsOf: exampleExpiredBills)
        result.append(contentsOf: exampleSubscriptions)
        result.append(contentsOf: exampleActualBills)
        
        return result
    }()
#endif
}

@Model
final class Utility: BillBase {
    init(_ name: String, amounts: [UtilityEntry], start: Date, end: Date? = nil, period: BillsPeriod = .monthly, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.startDate = start
        self.endDate = end
        self.rawPeriod = period.rawValue
        self.children = amounts
    }
    
    var id: UUID
    @Attribute(.unique) public var name: String
    var startDate: Date;
    var endDate: Date?
    var rawPeriod: Int;
    @Relationship(deleteRule: .cascade, inverse: \UtilityEntry.parent) var children: [UtilityEntry];
    
    var amount: Decimal {
        children.count == 0 ? Decimal() : children.reduce(0.0, { $0 + $1.amount } ) / Decimal(children.count)
    }
    var kind: BillsKind {
        .utility
    }
    var period: BillsPeriod {
        get { BillsPeriod(rawValue: rawPeriod)! }
        set { rawPeriod = newValue.rawValue }
    }
    
    #if DEBUG
    static let exampleUtility: [Utility] = {
        [
            .init(
                "Gas",
                amounts: [
                    .init(Date.fromParts(2025, 1, 25)!, 25),
                    .init(Date.fromParts(2025, 2, 25)!, 23),
                    .init(Date.fromParts(2025, 3, 25)!, 28),
                    .init(Date.fromParts(2025, 4, 25)!, 27)],
                start: Date.fromParts(2025, 1, 25)!,
                end: nil
            ),
            .init(
                "Electric",
                amounts: [
                    .init(Date.fromParts(2025, 1, 17)!, 30),
                    .init(Date.fromParts(2025, 2, 17)!, 31),
                    .init(Date.fromParts(2025, 3, 17)!, 35),
                    .init(Date.fromParts(2025, 4, 17)!, 32)],
                start: Date.fromParts(2025, 1, 17)!,
                end: nil
            ),
            .init(
                "Water",
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
    #endif
}

@Model
class UtilityEntry: Identifiable, Hashable, Equatable {
    init(_ date: Date, _ amount: Decimal, id: UUID = UUID()) {
        self.date = date
        self.amount = amount
        self.id = id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(amount)
    }
    static func ==(lhs: UtilityEntry, rhs: UtilityEntry) -> Bool {
        lhs.date == rhs.date && lhs.amount == rhs.amount
    }
    
    var id: UUID;
    var date: Date;
    var amount: Decimal;
    @Relationship var parent: Utility?;
}
