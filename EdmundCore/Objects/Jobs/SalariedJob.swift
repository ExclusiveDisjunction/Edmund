//
//  SalariedJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftData
import Foundation

@Model
public final class SalariedJob : Identifiable, InspectableElement, EditableElement, TraditionalJob {
    public typealias InspectorView = SalariedJobInspector;
    public typealias EditView = SalariedJobEdit;
    public typealias Snapshot = SalariedJobSnapshot;
    
    public convenience init() {
        self.init(company: "", position: "", grossAmount: 0.0, taxRate: 0.0)
    }
    public init(company: String, position: String, grossAmount: Decimal, taxRate: Decimal, id: UUID = UUID()) {
        self.company = company
        self.position = position
        self.grossAmount = grossAmount
        self.taxRate = taxRate
        self.id = id
    }
    
    public static var typeDisplay: TypeTitleStrings {
        .init(
            singular: "Salaried Job",
            plural: "Salaried Jobs",
            inspect: "Inspect Salaried Job",
            edit: "Edit Salaried Job",
            add: "Add Salaried Job"
        )
    }
    
    public var id: UUID;
    public var company: String;
    public var position: String;
    public var grossAmount: Decimal;
    public var taxRate: Decimal;
}


@Observable
public final class SalariedJobSnapshot : ElementSnapshot {
    public typealias Host = SalariedJob
    
    public init(_ from: SalariedJob) {
        self.company = from.company
        self.position = from.position
        self.grossAmount = .init(rawValue: from.grossAmount)
        self.taxRate = from.taxRate
    }
    
    public var company: String;
    public var position: String;
    public var grossAmount: CurrencyValue;
    public var taxRate: Decimal;
    
    public func validate() -> Bool {
        !company.trimmingCharacters(in: .whitespaces).isEmpty && !position.trimmingCharacters(in: .whitespaces).isEmpty && grossAmount.rawValue >= 0.0 && taxRate >= 0.0 && taxRate < 1.0;
    }
    public func apply(_ to: SalariedJob, context: ModelContext) {
        to.company = self.company
        to.position = self.position
        to.grossAmount = self.grossAmount.rawValue
        to.taxRate = self.taxRate
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(company)
        hasher.combine(position)
        hasher.combine(grossAmount)
        hasher.combine(taxRate)
    }
    
    public static func == (lhs: SalariedJobSnapshot, rhs: SalariedJobSnapshot) -> Bool {
        lhs.company == rhs.company && lhs.position == rhs.position && lhs.grossAmount == rhs.grossAmount && lhs.taxRate == rhs.taxRate
    }
    
    
}
