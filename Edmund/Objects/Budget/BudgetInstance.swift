//
//  BudgetInstance.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension BudgetInstance : EditableElement, InspectableElement {
    public typealias EditView = BudgetEdit
    public typealias InspectView = BudgetInspect;
    
    public func makeInspectView() -> some View {
        BudgetInspect(data: self)
    }
    public static func makeEditView(_ snap: Snapshot) -> BudgetEdit {
        BudgetEdit(snap)
    }
}

extension DevotionGroup : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
            default: "internalError"
        }
    }
}

extension IncomeKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .pay: "Pay"
            case .gift: "Gift"
            case .donation: "Donation"
            default: "internalError"
        }
    }
}
