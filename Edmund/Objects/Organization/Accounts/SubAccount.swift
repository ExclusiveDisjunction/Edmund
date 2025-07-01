//
//  SubAccount.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension SubAccount : TypeTitled  {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Sub Account",
            plural:   "Sub Accounts",
            inspect:  "Inspect Sub Account",
            edit:     "Edit Sub Account",
            add:      "Add Sub Account"
        )
    }
}
