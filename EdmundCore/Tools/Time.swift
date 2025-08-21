//
//  TimePeriodWalker.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import Foundation

public enum TimePeriods: Int, CaseIterable, Identifiable, Equatable, Sendable {
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
    private static let compTable: [[Decimal]] =
    [
        //   Week        Bi-Week     Month       Bi-Month  Quarter  HYear  Year
        [1.0       , 2.0       , 4.0       , 8.0     , 12.0   , 26.0 , 52.0],
        [0.5       , 1.0       , 2.0       , 4.0     , 6.0    , 12.0 , 26.0],
        [0.25      , 0.5       , 1.0       , 2.0     , 4.0    , 6.0  , 12.0],
        [0.125     , 0.25      , 0.5       , 1.0     , 2.0    , 4.0  , 6.0 ],
        [0.08333333, 0.16666667, 0.25      , 0.5     , 1.0    , 2.0  , 4.0 ],
        [0.03846154, 0.08333333, 0.16666667, 0.25    , 0.5    , 1.0  , 2.0 ],
        [0.01923077, 0.03846154, 0.08333333, 0.0625  , 0.25   , 0.5  , 1.0 ]
    ]
    
    public func conversionFactor(_ to: TimePeriods) -> Decimal {
        let i = self.index, j = to.index
        
        return TimePeriods.compTable[i][j]
    }
    public var asComponents: DateComponents {
        switch self {
            case .weekly:      .init(weekOfYear: 1)
            case .biWeekly:    .init(weekOfYear: 2)
            case .monthly:     .init(month: 1)
            case .biMonthly:   .init(month: 2)
            case .quarterly:   .init(month: 3)
            case .semiAnually: .init(month: 6)
            case .anually:     .init(year: 1)
        }
    }
    
    public var id: Self { self }
}

public enum MonthlyTimePeriods : Int, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case weekly = 0
    case biWeekly = 1
    case monthly = 2
    
    private var index: Int {
        self.rawValue
    }
    private static let facTable: [[Decimal]] =
    [
        //   Week,  Bi-Week, Month
        [ 1.0,  2.0,     4.0 ],
        [ 0.5,  1.0,     2.0 ],
        [ 0.25, 0.5,     1.0 ]
    ];
    
    public func conversionFactor(_ to: MonthlyTimePeriods) -> Decimal {
        let i = self.index, j = to.index;
        
        return Self.facTable[i][j];
    }
    public var asComponents: DateComponents {
        switch self {
            case .weekly:      .init(weekOfYear: 1)
            case .biWeekly:    .init(weekOfYear: 2)
            case .monthly:     .init(month: 1)
        }
    }
    
    public var id: Self { self }
}

public extension Date {
    static func fromParts(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }
}

public struct TimePeriodWalker {
    public init(start: Date, end: Date?, period: TimePeriods, calendar: Calendar) {
        if let end = end {
            assert(start < end, "The start date cannot be greater than or equal to the end date.")
        }
        
        self.start = start
        self.end = end
        self.period = period.asComponents
        self.calendar = calendar
        self.current = start
    }
    
    public let start: Date;
    public let end: Date?;
    public let calendar: Calendar;
    public private(set) var current: Date?;
    private let period: DateComponents;
    
    public mutating func reset() {
        self.current = start
    }
    
    public mutating func step() -> Date? {
        guard let current = self.current else { //This value will be the return value
            return nil
        }
        
        guard let nextDate: Date = calendar.date(byAdding: period, to: current) else { //this value will be the value in the next call
            return nil
        }
        
        if let end = end, nextDate > end {
            self.current = nil
        }
        else {
            self.current = nextDate
        }
        
        return current
    }
    public mutating func walkToDate(relativeTo: Date) -> Date? {
        guard start <= relativeTo else {
            if let end = end, start > end {
                return nil
            }
            
            return start
        }
        
        guard var current = self.current else {
            return nil
        }
        
        while current <= relativeTo {
            guard let value = self.step() else {
                return nil
            }
            
            current = value
        }
        
        if let end = end, current > end {
            return nil
        }
        
        return current
    }
    public mutating func step(periods: Int) -> [Date]? {
        guard self.current != nil else {
            return nil
        }
        
        var result: [Date] = [];
        var n = periods;
        while n >= 0 {
            if let nextDate = self.step() {
                result.append(nextDate)
                n -= 1
            }
            else {
                // The current next date could not be obtained. If this is because the current is nil (only happens when the end has been passed, we can just return now.
                if self.current == nil {
                    return result
                }
                else {
                    return nil //This means there was an internal error
                }
            }
        }
        
        return result
    }
}
