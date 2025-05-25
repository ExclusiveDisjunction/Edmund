//
//  HourlyJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftData
import Foundation

@Model
public final class HourlyJob : Identifiable, InspectableElement, EditableElement {
    public typealias InspectorView = HourlyJobInspect
    public typealias EditView = HourlyJobEdit
    public typealias Snapshot = HourlyJobSnapshot
    
    init(company: String, position: String, hourlyRate: Decimal, avgHours: Decimal, id: UUID = UUID()) {
        self.company = company
        self.position = position
        self.hourlyRate = hourlyRate
        self.avgHours = avgHours
        self.id = id
    }
    
    public var id: UUID;
    public var company: String;
    public var position: String;
    public var hourlyRate: Decimal;
    public var avgHours: Decimal;
}

@Observable
public final class HourlyJobSnapshot : Identifiable, Equatable, Hashable, ElementSnapshot {
    public init() {
        self.company = "";
        self.position = ""
        self.hourlyRate = .init(rawValue: 0.0);
        self.avgHours = 0.0;
    }
    public init(_ from: HourlyJob) {
        self.company = from.company
        self.position = from.position
        self.hourlyRate = .init(rawValue: from.hourlyRate)
        self.avgHours = from.avgHours
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
    
    public func validate() -> Bool {
        !self.company.trimmingCharacters(in: .whitespaces).isEmpty && !self.position.trimmingCharacters(in: .whitespaces).isEmpty  && hourlyRate >= 0
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
