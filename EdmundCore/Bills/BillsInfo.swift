//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftData
import SwiftUI
import Foundation

/// The bills kind that is used by the Bill class, as it does not include the utility kind.
public enum StrictBillsKind : Int, Equatable, Hashable, Codable, Identifiable {
    case subscription
    case bill
    
    public var id: Self { self }
}

@frozen
public enum BillsKind : Int, Equatable, Codable, Hashable, Comparable {
    public typealias On = BillBaseWrapper
    
    case bill = 0
    case subscription = 1
    case utility = 2
    
    public var id: Self { self }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum BillsSort : Int, Identifiable, CaseIterable {
    case name, amount, kind
    
    public var id: Self { self }
}

public extension Date {
    static func fromParts(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }
}

public enum TimePeriods: Int, CaseIterable, Identifiable, Equatable {
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
        //   Week      Bi-Week   Month     Bi-Month  Quarter  HYear    Year
            [1.0     , 2.0     , 4.0     , 8.0     , 12.0   , 26.0   , 52.0].map { Decimal($0) },
            [1.0/2.0 , 1.0     , 2.0     , 4.0     , 6.0    , 12.0   , 26.0].map { Decimal($0) },
            [1.0/4.0 , 1.0/2.0 , 1.0     , 2.0     , 4.0    , 6.0    , 12.0].map { Decimal($0) },
            [1.0/8.0 , 1.0/4.0 , 1.0/2.0 , 1.0     , 2.0    , 4.0    , 6.0 ].map { Decimal($0) },
            [1.0/12.0, 1.0/6.0 , 1.0/4.0 , 1.0/2.0 , 1.0    , 2.0    , 4.0 ].map { Decimal($0) },
            [1.0/26.0, 1.0/12.0, 1.0/6.0 , 1.0/4.0 , 1.0/2.0, 1.0    , 2.0 ].map { Decimal($0) },
            [1.0/52.0, 1.0/26.0, 1.0/12.0, 1.0/16.0, 1.0/4.0, 1.0/2.0, 1.0 ].map { Decimal($0) }
        ]
    private static let weeksTable: [Int] = [
        1,
        2,
        4,
        8,
        12,
        26,
        52
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
    public var weeksInPeriod: Int {
        Self.weeksTable[self.index]
    }
    
    public var id: Self { self }
}
