//
//  SubCategory.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension SubCategory : TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Sub Category",
            plural:   "Sub Categories",
            inspect:  "Inspect Sub Category",
            edit:     "Edit Sub Category",
            add:      "Add Sub Category"
        )
    }
}
