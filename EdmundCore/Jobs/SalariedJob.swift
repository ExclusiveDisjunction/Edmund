//
//  SalariedJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1 {
    /// Represents a job that has the same paycheck value each week.
    @Model
    public final class SalariedJob : Identifiable, UniqueElement, TraditionalJob, SnapshotableElement {
        public typealias Snapshot = SalariedJobSnapshot;
        
        /// Creates the job from default values.
        public convenience init() {
            self.init(company: "", position: "", grossAmount: 0.0, taxRate: 0.0)
        }
        /// Creates the job from filled in values.
        public init(company: String, position: String, grossAmount: Decimal, taxRate: Decimal) {
            self.company = company
            self.position = position
            self.grossAmount = grossAmount
            self.taxRate = taxRate
        }
        
        public static let objId: ObjectIdentifier = .init((any TraditionalJob).self)
        
        public var id: TraditionalJobID {
            .init(company: company, position: position)
        }
        public var company: String;
        public var position: String;
        /// The gross pay of the job each paycheck.
        public var grossAmount: Decimal;
        public var taxRate: Decimal;
        
        public func makeSnapshot() -> SalariedJobSnapshot {
            return .init(self)
        }
        public static func makeBlankSnapshot() -> SalariedJobSnapshot {
            return .init()
        }
        public func update(_ from: SalariedJobSnapshot, unique: UniqueEngine) async throws(UniqueFailureError<TraditionalJobID>) {
            try await self.updateBase(from, unique: unique)
            
            self.grossAmount = from.grossAmount.rawValue
        }
        
        @MainActor
        public static var exampleJob: SalariedJob {
            SalariedJob(company: "Winn Dixie", position: "Customer Service Manager", grossAmount: 850, taxRate: 0.25);
        }
    }
}

public typealias SalariedJob = EdmundModelsV1.SalariedJob

/// The snapshot value for `SalariedJob`
@Observable
public final class SalariedJobSnapshot : TraditionalJobSnapshot, ElementSnapshot {
    public typealias Host = SalariedJob
    
    /// Creates an empty snapshot.
    public override init() {
        self.grossAmount = .init()
        super.init()
    }
    /// Creates a snapshot from a specified value.
    public init(_ from: SalariedJob) {
        self.grossAmount = .init(rawValue: from.grossAmount)
        super.init(from)
    }
    
    /// The gross take home pay from the job.
    public var grossAmount: CurrencyValue;
    
    public override func validate(unique: UniqueEngine) async -> ValidationFailure? {
        if let topResult = await super.validate(unique: unique) {
            return topResult
        }
        
        if grossAmount < 0 { return .negativeAmount }
        
        return nil
    }
    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(grossAmount)
    }
    
    public static func == (lhs: SalariedJobSnapshot, rhs: SalariedJobSnapshot) -> Bool {
        (lhs as TraditionalJobSnapshot) == (rhs as TraditionalJobSnapshot) && lhs.grossAmount == rhs.grossAmount
    }
}
