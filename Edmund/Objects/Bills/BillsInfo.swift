//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import EdmundCore
import SwiftUI

/// The bills kind that is used by the Bill class, as it does not include the utility kind.
public enum StrictBillsKind : Int, Equatable, Hashable, Codable, Identifiable, CaseIterable, Sendable {
    case subscription
    case bill
    
    public var id: Self { self }
}

@frozen
public enum BillsKind : Int, Equatable, Codable, Hashable, Comparable, Filterable, Sendable {
    public typealias On = Bill
    
    case bill = 0
    case subscription = 1
    case utility = 2
    
    public var id: Self { self }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum BillsSort : Int, Identifiable, CaseIterable, Sortable, Sendable {
    case name, amount, kind
    
    public var id: Self { self }
}

extension BillsKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription"
            case .bill: "Bill"
            case .utility: "Utility"
        }
    }
    
    public var title: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription Payment"
            case .bill: "Bill Payment"
            case .utility: "Utility Payment"
        }
    }
}

extension BillsSort : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .name: "Name"
            case .amount: "Amount"
            case .kind: "Kind"
            default: "internalError"
        }
    }
}

public extension TimePeriods {
    var perName: LocalizedStringKey {
        switch self {
            case .weekly:      "Week"
            case .biWeekly:    "Two Weeks"
            case .monthly:     "Month"
            case .biMonthly:   "Two Months"
            case .quarterly:   "Quarter"
            case .semiAnually: "Half Year"
            case .anually:     "Year"
            default: "internalError"
        }
    }
}
extension TimePeriods : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .weekly:       "Weekly"
            case .biWeekly:     "Bi-Weekly"
            case .monthly:      "Monthly"
            case .biMonthly:    "Bi-Monthly"
            case .quarterly:    "Quarterly"
            case .semiAnually:  "Semi-Anually"
            case .anually:      "Anually"
            default: "internalError"
        }
    }
}
