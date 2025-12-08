//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI

/*
 extension IncomeDivision : EditableElement, InspectableElement {
 public typealias EditView = IncomeDivisionEdit
 public typealias InspectView = IncomeDivisionInspect;
 
 public func makeInspectView() -> some View {
 IncomeDivisionInspect(data: self)
 }
 public static func makeEditView(_ snap: Snapshot) -> IncomeDivisionEdit {
 IncomeDivisionEdit(snap)
 }
 }
 */

extension DevotionGroup : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
        }
    }
}

extension IncomeKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .pay: "Pay"
            case .gift: "Gift"
            case .donation: "Donation"
        }
    }
}

extension MonthlyTimePeriods : Displayable {
    public var display: LocalizedStringKey {
        switch self {
        case .weekly: "Weekly"
        case .biWeekly: "Bi-Weekly"
        case .monthly: "Monthly"
        }
    }
}
