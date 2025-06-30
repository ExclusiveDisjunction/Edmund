//
//  Bill.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import EdmundCore

extension Bill : NamedInspectableElement, NamedEditableElement, TypeTitled {
    public func makeInspectView() -> BillInspect {
        BillInspect(self)
    }
    public static func makeEditView(_ snap: BillSnapshot) -> BillEdit {
        BillEdit(snap)
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Bill",
            plural:   "Bills",
            inspect:  "Inspect Bill",
            edit:     "Edit Bill",
            add:      "Add Bill"
        )
    }
}
