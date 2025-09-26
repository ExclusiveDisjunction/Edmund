//
//  Jobs.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import SwiftData
import Foundation

extension EdmundModelsV1_1 {
    /// Represents a job that has the same paycheck value each week.
    @Model
    public final class SalariedJob : Identifiable {
        /// Creates the job from filled in values.
        public init(company: String, position: String, grossAmount: Decimal, taxRate: Decimal) {
            self.company = company
            self.position = position
            self.grossAmount = grossAmount
            self.taxRate = taxRate
            self.id = UUID();
        }
        public init(migration: EdmundModelsV1.SalariedJob) {
            self.company = migration.company
            self.position = migration.position
            self.grossAmount = migration.grossAmount
            self.taxRate = migration.taxRate
            self.id = UUID();
        }
        
        public var id: UUID = UUID();
        public var company: String = "";
        public var position: String = "";
        /// The gross pay of the job each paycheck.
        public var grossAmount: Decimal = 0;
        public var taxRate: Decimal = 0;
    }
    
    /// A hourly job taken at a company
    @Model
    public final class HourlyJob : Identifiable {
        /// Creates the hourly job with specific values.
        public init(company: String, position: String, hourlyRate: Decimal, avgHours: Decimal, taxRate: Decimal) {
            self.company = company
            self.position = position
            self.hourlyRate = hourlyRate
            self.avgHours = avgHours
            self.taxRate = taxRate
            self.id = UUID();
        }
        public init(migration: EdmundModelsV1.HourlyJob) {
            self.company = migration.company
            self.position = migration.position
            self.hourlyRate = migration.hourlyRate
            self.avgHours = migration.avgHours
            self.taxRate = migration.taxRate
            self.id = UUID();
        }
        
        public var id: UUID = UUID();
        public var company: String = "";
        public var position: String = "";
        /// The amount per hour the individual obtains (ex. 20$ per hour)
        public var hourlyRate: Decimal = 0;
        /// The average hours the individual works.
        public var avgHours: Decimal = 0;
        public var taxRate: Decimal = 0;
    }
}
