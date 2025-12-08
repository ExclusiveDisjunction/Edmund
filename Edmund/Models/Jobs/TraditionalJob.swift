//
//  TraditionalJob.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import Foundation
import CoreData

extension IncomeSource {
    public var taxRate: Decimal {
        get { (self.internalTaxRate as Decimal?) ?? 0.0 }
        set { self.internalTaxRate = newValue as NSDecimalNumber }
    }
    @objc open var grossAmount: Decimal {
        get { 0.0 }
    }
    /// The average amount gained (post-tax).
    public var estimatedProfit : Decimal {
        grossAmount * (1 - taxRate)
    }
}


/// Represents a job that takes place at a company, meaning that there is a company and position that you work.
public extension TraditionalJob {
    /// The company that is being worked for
    var company: String {
        get { self.internalCompany ?? "" }
        set { self.internalCompany = newValue }
    }
    /// The role that the individual works.
    var position: String  {
        get { self.internalPosition ?? "" }
        set { self.internalPosition = newValue }
    }
    
    static func examples(cx: NSManagedObjectContext) {
        let hourly = HourlyJob(context: cx);
        hourly.company = "Lowes";
        hourly.position = "Customer Service Associate";
        hourly.avgHours = 20;
    }
}
