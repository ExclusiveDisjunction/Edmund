//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import EdmundCore
import SwiftUI

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

extension StrictBillsKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription"
            case .bill: "Bill"
            default: "internalError"
        }
    }
    
    public var title: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription Payment"
            case .bill: "Bill Payment"
            default: "internalError"
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
