//
//  Account.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension AccountKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .credit: "Credit"
            case .checking: "Checking"
            case .savings: "Savings"
            case .cd: "Certificate of Deposit"
            case .trust: "Trust Fund"
            case .cash: "Cash"
            default: "internalError"
        }
    }
}

extension Account: EditableElement, InspectableElement, TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Account",
            plural:   "Accounts",
            inspect:  "Inspect Account",
            edit:     "Edit Account",
            add:      "Add Account"
        )
    }
    
    public func makeInspectView() -> AccountInspect {
        AccountInspect(self)
    }
    public static func makeEditView(_ snap: Snapshot) -> AccountEdit {
        AccountEdit(snap)
    }
}
