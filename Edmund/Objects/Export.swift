//
//  Export.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/9/25.
//

import SwiftData
import EdmundCore
import Foundation



public struct EdmundExportV1 : Sendable, Codable {
    public struct Account : Sendable, Codable {
        public init(from: EdmundCore.Account) {
            self.name = from.name;
            self.interest = from.interest;
            self.location = from.location;
            self.isVoided = from.isVoided;
            self.kind = from.kind;
            self.creditLimit = from._creditLimit; //This is intentional
        }
        
        public let name: String;
        public let interest: Decimal?;
        public let location: String?;
        public let isVoided: Bool;
        public let kind: AccountKind;
        public let creditLimit: Decimal?;
    }
    public struct Category : Sendable, Codable {
        public init(from: EdmundCore.Category) {
            self.name = from.name
            self.desc = from.desc
            self.isLocked = from.isLocked
        }
        
        public let name: String;
        public let desc: String;
        public let isLocked: Bool;
    }
    public struct LedgerEntry : Sendable, Codable {
        public init(from: EdmundCore.LedgerEntry, category: UUID, account: UUID) {
            self.memo = from.name
            self.credit = from.credit
            self.debit = from.debit
            self.date = from.date
            self.addedOn = from.addedOn
            self.location = from.location
            self.isVoided = from.isVoided
            self.category = category
            self.account = account
        }
        
        public let memo: String;
        public let credit: Decimal;
        public let debit: Decimal;
        public let date: Date;
        public let addedOn: Date;
        public let location: String;
        public let isVoided: Bool ;
        public let category: UUID;
        public let account: UUID;
    }
    public struct Bill : Sendable, Codable {
        public init<T>(from: T) where T: BillBase {
            self.name = from.name;
            self.amount = from.amount;
            self.startDate = from.startDate;
            self.endDate = from.endDate;
            self.company = from.company;
            self.location = from.location;
            self.autoPay = from.autoPay;
            self.kind = from.kind;
            self.period = from.period
        }
        
        public let name: String;
        public let amount: Decimal;
        public let startDate: Date;
        public let endDate: Date?;
        public let company: String;
        public let location: String?;
        public let autoPay: Bool;
        public let kind: BillsKind;
        public let period: TimePeriods;
    }
    public struct BillDatapoint : Sendable, Codable {
        public init(from: UtilityDatapoint, parent: UUID) {
            self.order = from.id;
            self.amount = from.amount;
            self.parent = parent;
            self.parentIsBill = false;
        }
        public init(from: EdmundCore.BillDatapoint, parent: UUID) {
            self.order = from.id;
            self.amount = from.amount;
            self.parent = parent;
            self.parentIsBill = true;
        }
        
        public let order: Int;
        public let amount: Decimal?;
        public let parent: UUID;
        public let parentIsBill: Bool;
    }
    public struct Budget : Sendable, Codable {
        public init(from: BudgetMonth) {
            self.date = from.date;
        }
        public let date: MonthYear;
    }
    public struct BudgetGoal : Sendable, Codable {
        public init(from: BudgetSavingsGoal, parent: UUID) {
            self.amount = from.amount;
            self.period = from.period;
            self.association = parent;
            self.isSavings = true;
        }
        public init(from: BudgetSpendingGoal, parent: UUID) {
            self.amount = from.amount;
            self.period = from.period;
            self.association = parent;
            self.isSavings = false;
        }
        
        public let amount: Decimal;
        public let period: MonthlyTimePeriods;
        public let association: UUID;
        public let isSavings: Bool;
    }
    public struct IncomeDivision : Sendable, Codable {
        public init(from: IncomeDivision, parent: UUID, depositTo: UUID) {
            self.parent = parent;
            self.depositTo = depositTo;
            
            self.name = from.name;
            self.amount = from.amount;
            self.isFinalized = from.isFinalized;
            self.kind = from.kind
            self.lastUpdated = from.lastUpdated;
            self.lastViewed = from.lastViewed;
        }
        
        public let name: String;
        public let amount: Decimal;
        public let isFinalized: Bool;
        public let kind: IncomeKind;
        public let lastUpdated: Date;
        public let lastViewed: Date;
        public let parent: UUID;
        public let depositTo: UUID;
    }
    public enum DevotionAmount : Sendable, Codable {
        case amount(Decimal)
        case percent(Decimal)
        case remainder
    }
    public struct IncomeDevotion : Sendable, Codable {
        public init(from: AmountDevotion, parent: UUID, account: UUID) {
            self.parent = parent;
            self.account = account;
            self.amount = .amount(from.amount)
            self.name = from.name;
            self.group = from.group;
        }
        public init(from: PercentDevotion, parent: UUID, account: UUID) {
            self.parent = parent;
            self.account = account;
            self.amount = .percent(from.amount)
            self.name = from.name;
            self.group = from.group;
        }
        public init(from: RemainderDevotion, parent: UUID, account: UUID) {
            self.parent = parent;
            self.account = account;
            self.amount = .remainder
            self.name = from.name;
            self.group = from.group;
        }
        
        public let parent: UUID;
        public let amount: DevotionAmount;
        public let name: String;
        public let group: DevotionGroup;
        public let account: UUID;
    }
    public struct HourlyJob : Sendable, Codable {
        public init(from: EdmundCore.HourlyJob) {
            self.company = from.company;
            self.position = from.position;
            self.avgHours = from.avgHours;
            self.hourlyRate = from.hourlyRate;
            self.taxRate = from.taxRate
        }
        
        public let company: String;
        public let position: String;
        public let avgHours: Decimal;
        public let hourlyRate: Decimal;
        public let taxRate: Decimal;
    }
    public struct SalariedJob : Sendable, Codable {
        public init(from: EdmundCore.SalariedJob) {
            self.company = from.company
            self.position = from.position
            self.grossAmount = from.grossAmount
            self.taxRate = from.taxRate
        }
        
        public let company: String;
        public let position: String;
        public let grossAmount: Decimal;
        public let taxRate: Decimal;
    }

    public var accounts: [UUID : Self.Account];
    public var categories: [UUID : Self.Category];
    public var ledgerEntries: [UUID : Self.LedgerEntry];
    public var bills: [UUID : Self.Bill];
    public var billHistories: [UUID : Self.BillDatapoint];
    public var budgets: [UUID : Self.Budget];
    public var budgetGoals: [UUID : Self.BudgetGoal];
    public var incomeDivisions: [UUID : Self.IncomeDivision];
    public var incomeDevotions: [UUID : Self.IncomeDevotion];
    public var hourlyJobs: [UUID : Self.HourlyJob];
    public var salariedJob: [UUID : Self.SalariedJob];
}
