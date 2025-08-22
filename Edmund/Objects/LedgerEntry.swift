//
//  LedgerEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension LedgerEntry : EditableElement, InspectableElement, TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Transaction",
            plural:   "Transactions",
            inspect:  "Inspect Transaction",
            edit:     "Edit Transaction",
            add:      "Add Transaction"
        )
    }
    
    public func makeInspectView() -> LedgerEntryInspect {
        LedgerEntryInspect(self)
    }
    public static func makeEditView(_ snap: LedgerEntrySnapshot) -> LedgerEntryEdit {
        LedgerEntryEdit(snap)
    }
}
