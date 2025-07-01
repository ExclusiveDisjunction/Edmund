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

public extension DevotionGroup {
    var display: LocalizedStringKey {
        switch self {
            case .need: "Need"
            case .want: "Want"
            case .savings: "Savings"
            default: "internalError"
        }
    }
}
