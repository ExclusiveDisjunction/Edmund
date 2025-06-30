//
//  Utility.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI
import EdmundCore

extension Utility : NamedEditableElement, NamedInspectableElement, TypeTitled {
    public func makeInspectView() -> UtilityInspect {
        UtilityInspect(self)
    }
    public static func makeEditView(_ snap: UtilitySnapshot) -> UtilityEdit {
        UtilityEdit(snap)
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Utility",
            plural:   "Utilities",
            inspect:  "Inspect Utility",
            edit:     "Edit Utility",
            add:      "Add Utility"
        )
    }
}
