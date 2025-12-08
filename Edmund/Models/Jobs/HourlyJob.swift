//
//  HourlyJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import CoreData

extension HourlyJob {
    public var hourlyRate: Decimal {
        get { (self.internalHourlyRate as Decimal?) ?? 0.0 }
        set { self.internalHourlyRate = newValue as NSDecimalNumber }
    }
    public var avgHours: Decimal {
        get { (self.internalAvgHours as Decimal?) ?? 0.0 }
        set { self.internalAvgHours = newValue as NSDecimalNumber }
    }
    @objc public override var grossAmount: Decimal {
        get { hourlyRate * avgHours }
    }
}

/*
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
 */

