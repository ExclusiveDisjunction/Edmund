//
//  Jobs.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/21/25.
//

import Foundation
import SwiftData

extension EdmundModelsV1 {
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
        }
        
        @Transient
        public var id: UUID = UUID();
        public var company: String;
        public var position: String;
        /// The amount per hour the individual obtains (ex. 20$ per hour)
        public var hourlyRate: Decimal;
        /// The average hours the individual works.
        public var avgHours: Decimal;
        public var taxRate: Decimal;
    }
    
    /// Represents a job that has the same paycheck value each week.
    @Model
    public final class SalariedJob : Identifiable {
        /// Creates the job from filled in values.
        public init(company: String, position: String, grossAmount: Decimal, taxRate: Decimal) {
            self.company = company
            self.position = position
            self.grossAmount = grossAmount
            self.taxRate = taxRate
        }
        
        @Transient
        public var id: UUID = UUID();
        public var company: String;
        public var position: String;
        /// The gross pay of the job each paycheck.
        public var grossAmount: Decimal;
        public var taxRate: Decimal;
    }
}
