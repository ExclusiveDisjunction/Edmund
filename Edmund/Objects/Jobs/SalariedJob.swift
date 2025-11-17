//
//  SalariedJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI
import EdmundCore

extension SalariedJob : SnapshotableElement {
    public typealias Snapshot = SalariedJobSnapshot;
    
    public func makeSnapshot() -> SalariedJobSnapshot {
        return .init(self)
    }
    public static func makeBlankSnapshot() -> SalariedJobSnapshot {
        return .init()
    }
    public func update(_ from: SalariedJobSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        try await self.updateBase(from, unique: unique)
        
        self.grossAmount = from.grossAmount.rawValue
    }
}
extension SalariedJob : UniqueElement {
    public static let objId: ObjectIdentifier = .init((any TraditionalJob).self)
    
    public var uID: TraditionalJobID {
        .init(company: company, position: position)
    }
}
extension SalariedJob : TraditionalJob {
    
}
extension SalariedJob : InspectableElement {
    public typealias InspectorView = SalariedJobInspector;
    
    public func makeInspectView() -> SalariedJobInspector {
        SalariedJobInspector(self)
    }
}
extension SalariedJob : EditableElement {
    public typealias EditView = SalariedJobEdit;
    
    public static func makeEditView(_ snap: SalariedJobSnapshot) -> SalariedJobEdit {
        SalariedJobEdit(snap)
    }
}
extension SalariedJob : TypeTitled {
    public static var typeDisplay: TypeTitleStrings {
        .init(
            singular: "Salaried Job",
            plural: "Salaried Jobs",
            inspect: "Inspect Salaried Job",
            edit: "Edit Salaried Job",
            add: "Add Salaried Job"
        )
    }
}
public extension SalariedJob {
    /// Creates the job from default values.
    convenience init() {
        self.init(company: "", position: "", grossAmount: 0.0, taxRate: 0.0)
    }
    
    @MainActor
    static var exampleJob: SalariedJob {
        SalariedJob(company: "Winn Dixie", position: "Customer Service Manager", grossAmount: 850, taxRate: 0.25);
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
