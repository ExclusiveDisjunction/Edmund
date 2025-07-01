//
//  HourlyJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension HourlyJob : EditableElement, InspectableElement, TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Hourly Job",
            plural:   "Hourly Jobs",
            inspect:  "Inspect Hourly Job",
            edit:     "Edit Hourly Job",
            add:      "Add Hourly Job"
        )
    }
    
    public func makeInspectView() -> HourlyJobInspect{
        HourlyJobInspect(self)
    }
    public static func makeEditView(_ snap: HourlyJobSnapshot) -> HourlyJobEdit {
        HourlyJobEdit(snap)
    }
}
