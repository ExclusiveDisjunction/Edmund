//
//  Export.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/9/25.
//

import SwiftData
import Foundation



public struct EdmundExportV1 : Sendable, Codable {
    public struct Account : Sendable, Codable {
        
    }
    public struct Category : Sendable, Codable {
        
    }
    public struct LedgerEntry : Sendable, Codable {
        
    }
    public struct Bill : Sendable, Codable {
        
    }
    public struct BillDatapoint : Sendable, Codable {
        
    }
    public struct Utility : Sendable, Codable {
        
    }
    public struct UtilityDatapoint : Sendable, Codable {
        
    }
    public struct Budget : Sendable, Codable {
        
    }
    public struct BudgetSpendingGoal : Sendable, Codable {
        
    }
    public struct BudgetSavingsGoal : Sendable, Codable {
        
    }
    public struct IncomeDivision : Sendable, Codable {
        
    }
    public enum DevotionAmount : Sendable, Codable {
        case amount(Decimal)
        case percent(Decimal)
        case remainder
    }
    public struct IncomeDevotion : Sendable, Codable {
        
    }
    public struct HourlyJob : Sendable, Codable {
        
    }
    public struct SalariedJob : Sendable, Codable {
        
    }

    public var accounts: [Self.Account];
    public var categories: [Self.Category];
    public var ledgerEntries: [Self.LedgerEntry];
    public var bills: [Self.Bill];
    public var utilities: [Self.Utility];
    public var billHistories: [Self.BillDatapoint];
    public var utilityHistories: [Self.UtilityDatapoint];
    public var budgets: [Self.Budget];
    public var budgetSpending: [Self.BudgetSpendingGoal];
    public var budgetSavings: [Self.BudgetSavingsGoal];
    public var incomeDivisions: [Self.IncomeDivision];
    public var incomeDevotions: [Self.IncomeDevotion];
    public var hourlyJobs: [Self.HourlyJob];
    public var salariedJob: [Self.SalariedJob];
}
