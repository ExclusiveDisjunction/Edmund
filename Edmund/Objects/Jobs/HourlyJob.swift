//
//  HourlyJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension HourlyJob : SnapshotableElement {
    public typealias Snapshot = HourlyJobSnapshot
    
    public func makeSnapshot() -> HourlyJobSnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> HourlyJobSnapshot {
        .init()
    }
    public func update(_ from: HourlyJobSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        try await self.updateBase(from, unique: unique)
        
        self.avgHours = from.avgHours
        self.hourlyRate = from.hourlyRate.rawValue
    }
}
extension HourlyJob : UniqueElement {
    public static let objId: ObjectIdentifier = .init((any TraditionalJob).self)
    
    public var uID: TraditionalJobID {
        .init(company: company, position: position)
    }
}
extension HourlyJob : TraditionalJob {
    
}
extension HourlyJob : TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Hourly Job",
            plural:   "Hourly Jobs",
            inspect:  "Inspect Hourly Job",
            edit:     "Edit Hourly Job",
            add:      "Add Hourly Job"
        )
    }
}
extension HourlyJob : EditableElement {
    public typealias EditView = HourlyJobEdit;
    
    public static func makeEditView(_ snap: HourlyJobSnapshot) -> HourlyJobEdit {
        HourlyJobEdit(snap)
    }
}
extension HourlyJob : InspectableElement {
    public typealias InspectorView = HourlyJobInspect;
    
    public func makeInspectView() -> HourlyJobInspect {
        HourlyJobInspect(self)
    }
}
public extension HourlyJob {
    /// Creates the hourly job with default values for adding.
    convenience init() {
        self.init(company: "", position: "", hourlyRate: 0.0, avgHours: 0.0, taxRate: 0.0)
    }
    
    var grossAmount : Decimal {
        hourlyRate * avgHours
    }
    
    @MainActor
    static var exampleJob: HourlyJob {
        HourlyJob(company: "Winn Dixie", position: "Customer Service Associate", hourlyRate: 13.75, avgHours: 30, taxRate: 0.15)
    }
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
    
    /// The hourly rate of the job
    public var hourlyRate: CurrencyValue;
    /// The average number of hours the job has
    public var avgHours: Decimal;
    
    public override func validate(unique: UniqueEngine) async -> ValidationFailure? {
        if let topResult = await super.validate(unique: unique) {
            return topResult
        }
        
        if hourlyRate < 0 || avgHours < 0 { return .negativeAmount }
        
        return nil;
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

