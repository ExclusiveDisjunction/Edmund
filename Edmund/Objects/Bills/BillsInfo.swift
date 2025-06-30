//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import EdmundCore
import SwiftUI

public extension BillsKind {
    var display: LocalizedStringKey {
        switch self {
            case .subscription: "Subscription"
            case .bill: "Bill"
            case .utility: "Utility"
        }
    }
    var plural: LocalizedStringKey {
        switch self {
            case .subscription: "Subscriptions"
            case .bill: "Bills"
            case .utility: "Utilities"
        }
    }
}

public extension BillsSort {
    var display: LocalizedStringKey {
        switch self {
            case .name: "Name"
            case .amount: "Amount"
            case .kind: "Kind"
            default: "internalError"
        }
    }
    var ascendingQuestion: LocalizedStringKey {
        switch self {
            case .name: "Alphabetical"
            case .amount: "High to Low"
            case .kind: "Subscription to Utility"
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
    var name: LocalizedStringKey {
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
