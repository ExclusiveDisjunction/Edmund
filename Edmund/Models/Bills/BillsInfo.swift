//
//  BillsInfo.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI

@frozen
public enum BillsKind : Int16, Equatable, Codable, Hashable, Comparable, Sendable, CaseIterable, Identifiable {
    case bill = 0
    case subscription = 1
    case utility = 2
    
    public var id: Self { self }
    
    public static func <(lhs: BillsKind, rhs: BillsKind) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
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
