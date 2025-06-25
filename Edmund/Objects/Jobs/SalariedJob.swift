//
//  SalariedJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftData
import Foundation

/// Represents a job that has the same paycheck value each week.
@Model
public final class SalariedJob : Identifiable, InspectableElement, EditableElement, UniqueElement, TraditionalJob {
    public typealias InspectorView = SalariedJobInspector;
    public typealias EditView = SalariedJobEdit;
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
    
    public var id: TraditionalJobID {
        .init(company: company, position: position)
    }
    public var company: String;
    public var position: String;
    /// The gross pay of the job each paycheck.
    public var grossAmount: Decimal;
    public var taxRate: Decimal;
    
    public static var typeDisplay: TypeTitleStrings {
        .init(
            singular: "Salaried Job",
            plural: "Salaried Jobs",
            inspect: "Inspect Salaried Job",
            edit: "Edit Salaried Job",
            add: "Add Salaried Job"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Company"), .init(name: "Position") ]
    }
    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.job(id: self.id, action: .remove)
    }
}

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
    
    public override func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result = super.validate(unique: unique)
        
        if grossAmount < 0 { result.append(.negativeAmount("Gross Amount")) }
        
        return result
    }
    public func apply(_ to: SalariedJob, context: ModelContext, unique: UniqueEngine) throws(UniqueFailueError<TraditionalJobID>) {
        try super.apply(to, unique: unique)
        
        to.grossAmount = grossAmount.rawValue
    }
    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(grossAmount)
    }
    
    public static func == (lhs: SalariedJobSnapshot, rhs: SalariedJobSnapshot) -> Bool {
        (lhs as TraditionalJobSnapshot) == (rhs as TraditionalJobSnapshot) && lhs.grossAmount == rhs.grossAmount
    }
}
