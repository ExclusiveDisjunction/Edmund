//
//  Category.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension EdmundCore.Category : TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Category",
            plural:   "Categories",
            inspect:  "Inspect Category",
            edit:     "Edit Category",
            add:      "Add Category"
        )
    }
}
