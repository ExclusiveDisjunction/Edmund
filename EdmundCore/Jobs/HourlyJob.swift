//
//  HourlyJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftData
import Foundation

extension HourlyJob : SnapshotableElement, UniqueElement, TraditionalJob {
    public typealias Snapshot = HourlyJobSnapshot
    
    /// Creates the hourly job with default values for adding.
    public convenience init() {
        self.init(company: "", position: "", hourlyRate: 0.0, avgHours: 0.0, taxRate: 0.0)
    }
    
    public static let objId: ObjectIdentifier = .init((any TraditionalJob).self)
    
    public var uID: TraditionalJobID {
        .init(company: company, position: position)
    }
    public var grossAmount : Decimal {
        hourlyRate * avgHours
    }
    
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
    
    public static var exampleJob: HourlyJob {
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
    
    public typealias Host = HourlyJob
    
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
