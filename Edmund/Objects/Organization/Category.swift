//
//  Category.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension EdmundCore.Category : TypeTitled, EditableElement, InspectableElement {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Category",
            plural:   "Categories",
            inspect:  "Inspect Category",
            edit:     "Edit Category",
            add:      "Add Category"
        )
    }
    
    public func makeInspectView() -> some View {
        CategoryInspect(data: self)
    }
    public static func makeEditView(_ snap: CategorySnapshot) -> some View {
        CategoryEdit(snapshot: snap)
    }
}
