//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

public enum BillsKind : Int, Filterable, Equatable, Codable, Hashable {
    public typealias On = BillBaseWrapper
    
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
public enum BillsSort : Sortable {
    public typealias On = BillBaseWrapper;
    
    case name, amount, kind
    
    public var id: Self { self }
    public var toString: LocalizedStringKey {
        switch self {
            case .name: "Name"
            case .amount: "Amount"
            case .kind: "Kind"
        }
    }
    public var ascendingQuestion: LocalizedStringKey {
        switch self {
            case .name: "Alphabetical"
            case .amount: "High to Low"
            case .kind: "Subscription to Utility"
        }
    }
    
    public func compare(_ lhs: BillBaseWrapper, _ rhs: BillBaseWrapper, _ ascending: Bool) -> Bool {
        switch self {
            case .name: ascending ? lhs.data.name < rhs.data.name : lhs.data.name > rhs.data.name
            case .amount: ascending ? lhs.data.amount > rhs.data.amount : lhs.data.amount < rhs.data.amount
            case .kind: ascending ? lhs.data.kind < rhs.data.kind : lhs.data.kind > rhs.data.kind
        }
    }
}

public extension Date {
    static func fromParts(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }
}
public enum LongDuration : Equatable, Hashable {
    case years(Int), months(Int), weeks(Float)
    
    var weeksPer: Float {
        switch self {
            case .years(let v):  Float(v * 52 )
            case .months(let v): Float(v *  4 )
            case .weeks(let v):  v
        }
    }
    
    var asDateComponents: DateComponents {
        switch self {
            case .years(let year): DateComponents(year: year)
            case .months(let month): DateComponents(month: month)
            case .weeks(let weeks): DateComponents(day: Int(weeks * 7))
        }
    }
    
    public static func *(lhs: LongDuration, rhs: Int) -> LongDuration {
        switch lhs {
            case .years(let years): .years(years * rhs)
            case .months(let months): .months(months * rhs)
            case .weeks(let weeks): .weeks(weeks * Float(rhs))
        }
    }
    public static func *(rhs: Int, lhs: LongDuration) -> LongDuration {
        lhs * rhs
    }
    public static func *(lhs: LongDuration, rhs: Float) -> LongDuration {
        switch lhs {
            case .years(let years): .weeks(Float(years) * rhs * 52.0)
            case .months(let months): .weeks(Float(months) * rhs * 4.0)
            case .weeks(let weeks): .weeks(weeks * rhs)
        }
    }
    public static func *(rhs: Float, lhs: LongDuration) -> LongDuration {
        lhs * rhs
    }
    public static func +(lhs: LongDuration, rhs: Date) -> Date? {
        let calendar = Calendar.current
        return switch lhs {
            case .years(let years):   calendar.date(byAdding: .year,  value: years,          to: rhs)
            case .months(let months): calendar.date(byAdding: .month, value: months,         to: rhs)
            case .weeks(let weeks):   calendar.date(byAdding: .day,   value: Int(weeks * 7), to: rhs)
        }
    }
    public static func -(lhs: LongDuration, rhs: Date) -> Date? {
        (-1 * lhs) + rhs
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
        self.rawValue
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
    private static var weeksTable: [Int] = [
        1,
        2,
        4,
        8,
        12,
        26,
        52
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
    public var weeksInPeriod: Int {
        Self.weeksTable[self.index]
    }
    
    public var id: Self { self }
}

public enum InvalidBillFields : LocalizedStringKey, CaseIterable, Identifiable {
    case name = "Name", dates = "Start and End Dates", company = "Company", location = "Location", children = "Datapoints", amount = "Amount"
    
    public var description: LocalizedStringKey {
        switch self {
            case .name: "nameEmptyError"
            case .dates: "startDateError"
            case .company: "companyEmptyError"
            case .location: "locationEmptyError"
            case .children: "childrenError"
            case .amount: "negAmountError"
        }
    }
    
    public var id: Self { self }
}
