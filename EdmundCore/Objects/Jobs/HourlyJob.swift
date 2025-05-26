//
//  HourlyJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftData
import Foundation

/// A hourly job taken at a company
@Model
public final class HourlyJob : Identifiable, InspectableElement, EditableElement, TraditionalJob {
    public typealias InspectorView = HourlyJobInspect
    public typealias EditView = HourlyJobEdit
    public typealias Snapshot = HourlyJobSnapshot
    
    /// Creates the hourly job with default values for adding.
    public convenience init() {
        self.init(company: "", position: "", hourlyRate: 0.0, avgHours: 0.0, taxRate: 0.0)
    }
    /// Creates the hourly job with specific values.
    public init(company: String, position: String, hourlyRate: Decimal, avgHours: Decimal, taxRate: Decimal, id: UUID = UUID()) {
        self.company = company
        self.position = position
        self.hourlyRate = hourlyRate
        self.avgHours = avgHours
        self.id = id
        self.taxRate = taxRate
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Hourly Job",
            plural:   "Hourly Jobs",
            inspect:  "Inspect Hourly Job",
            edit:     "Edit Hourly Job",
            add:      "Add Hourly Job"
        )
    }
    
    public var id: UUID;
    public var company: String;
    public var position: String;
    /// The amount per hour the individual obtains (ex. 20$ per hour)
    public var hourlyRate: Decimal;
    /// The average hours the individual works.
    public var avgHours: Decimal;
    public var taxRate: Decimal;
    
    public var grossAmount : Decimal {
        hourlyRate * avgHours
    }
}

@Observable
public final class HourlyJobSnapshot : Identifiable, Equatable, Hashable, ElementSnapshot {
    public init() {
        self.company = "";
        self.position = ""
        self.hourlyRate = .init(rawValue: 0.0);
        self.avgHours = 0.0;
        self.taxRate = 0.0;
    }
    public init(_ from: HourlyJob) {
        self.company = from.company
        self.position = from.position
        self.hourlyRate = .init(rawValue: from.hourlyRate)
        self.avgHours = from.avgHours
        self.taxRate = from.taxRate;
    }
    public func apply(_ to: HourlyJob, context: ModelContext) {
        to.company = self.company
        to.position = self.position
        to.avgHours = self.avgHours
        to.hourlyRate = self.hourlyRate.rawValue
    }
    
    public typealias Host = HourlyJob
    
    public var company: String;
    public var position: String;
    public var hourlyRate: CurrencyValue;
    public var avgHours: Decimal;
    public var taxRate: Decimal;
    
    public func validate() -> Bool {
        !self.company.trimmingCharacters(in: .whitespaces).isEmpty && !self.position.trimmingCharacters(in: .whitespaces).isEmpty  && hourlyRate >= 0 && taxRate >= 0.0 && taxRate < 1.0;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(company)
        hasher.combine(position)
        hasher.combine(hourlyRate)
        hasher.combine(avgHours)
    }
    public static func == (lhs: HourlyJobSnapshot, rhs: HourlyJobSnapshot) -> Bool {
        lhs.company == rhs.company && lhs.position == rhs.position && lhs.hourlyRate == rhs.hourlyRate && lhs.avgHours == rhs.avgHours
    }
}
