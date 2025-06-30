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
public final class HourlyJob : InspectableElement, EditableElement, UniqueElement, TraditionalJob {
    public typealias InspectorView = HourlyJobInspect
    public typealias EditView = HourlyJobEdit
    public typealias Snapshot = HourlyJobSnapshot
    
    /// Creates the hourly job with default values for adding.
    public convenience init() {
        self.init(company: "", position: "", hourlyRate: 0.0, avgHours: 0.0, taxRate: 0.0)
    }
    /// Creates the hourly job with specific values.
    public init(company: String, position: String, hourlyRate: Decimal, avgHours: Decimal, taxRate: Decimal) {
        self.company = company
        self.position = position
        self.hourlyRate = hourlyRate
        self.avgHours = avgHours
        self.taxRate = taxRate
    }
    
    public var id: TraditionalJobID {
        .init(company: company, position: position)
    }
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
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Hourly Job",
            plural:   "Hourly Jobs",
            inspect:  "Inspect Hourly Job",
            edit:     "Edit Hourly Job",
            add:      "Add Hourly Job"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Company"), .init(name: "Position") ]
    }
    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.job(id: self.id, action: .remove)
    }
    
    @MainActor
    public static let exampleJob: HourlyJob = HourlyJob(company: "Winn Dixie", position: "Customer Service Associate", hourlyRate: 13.75, avgHours: 30, taxRate: 0.15);
}

@Observable
public final class HourlyJobSnapshot : TraditionalJobSnapshot, ElementSnapshot {
    public override init() {
        self.hourlyRate = .init(rawValue: 0.0);
        self.avgHours = 0.0;
        
        super.init()
    }
    public init(_ from: HourlyJob) {
        self.hourlyRate = .init(rawValue: from.hourlyRate)
        self.avgHours = from.avgHours
        
        super.init(from)
    }
    
    public typealias Host = HourlyJob
    
    /// The hourly rate of the job
    public var hourlyRate: CurrencyValue;
    /// The average number of hours the job has
    public var avgHours: Decimal;
    
    public override func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result = super.validate(unique: unique);
        
        if hourlyRate < 0 { result.append(.negativeAmount("Hourly Rate")) }
        if avgHours < 0 { result.append(.negativeAmount("Average Hours")) }
        
        return result;
    }
    public func apply(_ to: HourlyJob, context: ModelContext, unique: UniqueEngine) throws(UniqueFailueError<TraditionalJobID>) {
        try super.apply(to, unique: unique)
        
        to.hourlyRate = hourlyRate.rawValue
        to.avgHours = avgHours
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(hourlyRate)
        hasher.combine(avgHours)
        super.hash(into: &hasher)
    }
    public static func == (lhs: HourlyJobSnapshot, rhs: HourlyJobSnapshot) -> Bool {
        (lhs as TraditionalJobSnapshot) == (rhs as TraditionalJobSnapshot) && lhs.hourlyRate == rhs.hourlyRate && lhs.avgHours == rhs.avgHours
    }
}
