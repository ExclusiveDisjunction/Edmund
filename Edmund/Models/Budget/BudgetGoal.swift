//
//  BudgetGoal.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/26/25.
//

import Foundation
import CoreData
import Observation

extension BudgetGoal {
    public var amount: Decimal {
        get { (self.internalAmount as Decimal?) ?? 0.0 }
        set { self.internalAmount = newValue as NSDecimalNumber }
    }
    public var period: MonthlyTimePeriods {
        get { MonthlyTimePeriods(rawValue: self.internalPeriod) ?? .monthly }
        set { self.internalPeriod = newValue.rawValue }
    }
    
    public var monthlyGoal: Decimal {
        self.amount * period.conversionFactor(.monthly)
    }
}
