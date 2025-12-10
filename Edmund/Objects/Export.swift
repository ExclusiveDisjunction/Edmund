//
//  Export.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/9/25.
//

import SwiftData
import EdmundCore
import Foundation
import os
import UniformTypeIdentifiers
import SwiftUI

public extension UTType {
    static var edmundExport: UTType { UTType(exportedAs: "com.exdisj.Edmund.export") }
}

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
        public init(from: BudgetSavingsGoal, parent: UUID, association: UUID) {
            self.amount = from.amount;
            self.period = from.period;
            self.parent = parent;
            self.association = association;
            self.isSavings = true;
        }
        public init(from: BudgetSpendingGoal, parent: UUID, association: UUID) {
            self.amount = from.amount;
            self.period = from.period;
            self.parent = parent;
            self.association = association;
            self.isSavings = false;
        }
        
        public let amount: Decimal;
        public let period: MonthlyTimePeriods;
        public let association: UUID;
        public let parent: UUID;
        public let isSavings: Bool;
    }
    public struct IncomeDivision : Sendable, Codable {
        public init(from: EdmundCore.IncomeDivision, parent: UUID, depositTo: UUID) {
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
    
    public init(from: ModelContainer) throws {
        let context = ModelContext(from);
        let log = Logger(subsystem: "com.exdisj.Edmund", category: "Export")
        
        // Jobs first.
        do {
            let hourlyJobs = try context.fetch(FetchDescriptor<EdmundCore.HourlyJob>());
            let salariedJobs = try context.fetch(FetchDescriptor<EdmundCore.SalariedJob>());
            
            self.hourlyJobs = Dictionary(uniqueKeysWithValues: hourlyJobs.map { (UUID(), Self.HourlyJob(from: $0)) } );
            self.salariedJobs = Dictionary(uniqueKeysWithValues: salariedJobs.map { (UUID(), Self.SalariedJob(from: $0)) } );
        }
        
        var billsRelation: [BillBaseID : UUID] = [:];
        do {
            let bills = try context.fetch(FetchDescriptor<EdmundCore.Bill>());
            let utilities = try context.fetch(FetchDescriptor<EdmundCore.Utility>());
            
            self.bills = [:];
            
            for bill in bills {
                let id = UUID();
                billsRelation[bill.uID] = id;
                self.bills[id] = Self.Bill(from: bill);
            }
            for utility in utilities {
                let id = UUID();
                billsRelation[utility.uID] = id;
                self.bills[id] = Self.Bill(from: utility);
            }
        }
        
        do {
            let billDatapoints = try context.fetch(FetchDescriptor<EdmundCore.BillDatapoint>());
            let utilityDatapoints = try context.fetch(FetchDescriptor<EdmundCore.UtilityDatapoint>());
            
            self.billHistories = [:];
            
            for datapoint in billDatapoints {
                guard let parentId = datapoint.parent?.uID, let parentId = billsRelation[parentId] else {
                    log.warning("Unable to find the parent for entry \(datapoint.persistentModelID.entityName).\(String(describing: datapoint.persistentModelID.id)).");
                    continue;
                }
                
                self.billHistories[UUID()] = Self.BillDatapoint(from: datapoint, parent: parentId);
            }
            
            for datapoint in utilityDatapoints {
                guard let parentId = datapoint.parent?.uID, let parentId = billsRelation[parentId] else {
                    log.warning("Unable to find the parent for entry \(datapoint.persistentModelID.entityName).\(String(describing: datapoint.persistentModelID.id)).");
                    continue;
                }
                
                self.billHistories[UUID()] = Self.BillDatapoint(from: datapoint, parent: parentId);
            }
        }
        
        var accountRelation: [String : UUID] = [:];
        var categoryRelation: [String : UUID] = [:];
        do {
            let accounts = try context.fetch(FetchDescriptor<EdmundCore.Account>());
            let categories = try context.fetch(FetchDescriptor<EdmundCore.Category>());
            
            self.accounts = [:];
            self.categories = [:];
            
            for account in accounts {
                let id = UUID();
                accountRelation[account.name] = id;
                self.accounts[id] = Self.Account(from: account);
            }
            
            for category in categories {
                let id = UUID();
                categoryRelation[category.name] = id;
                self.categories[id] = Self.Category(from: category);
            }
        }
        
        do {
            let entries = try context.fetch(FetchDescriptor<EdmundCore.LedgerEntry>());
            
            self.ledgerEntries = [:];
            
            for entry in entries {
                guard let parentAccountId = entry.account?.name,
                      let parentCategoryId = entry.category?.name,
                      let parentAccount = accountRelation[parentAccountId],
                      let parentCategory = categoryRelation[parentCategoryId] else {
                    log.warning("Unable to find the parent for entry \(entry.persistentModelID.entityName).\(String(describing: entry.persistentModelID.id)).");
                    continue;
                }
                
                self.ledgerEntries[UUID()] = Self.LedgerEntry(from: entry, category: parentCategory, account: parentAccount);
            }
        }
        
        var budgetRelation: [PersistentIdentifier : UUID] = [:];
        do {
            let budgets = try context.fetch(FetchDescriptor<EdmundCore.BudgetMonth>());
            
            self.budgets = [:];
            for budget in budgets {
                let id = UUID();
                budgetRelation[budget.persistentModelID] = id;
                self.budgets[id] = Self.Budget(from: budget);
            }
        }
        
        do {
            let savingsGoals = try context.fetch(FetchDescriptor<EdmundCore.BudgetSavingsGoal>());
            let spendingGoals = try context.fetch(FetchDescriptor<EdmundCore.BudgetSpendingGoal>());
            
            self.budgetGoals = [:];
            for goal in savingsGoals {
                guard let parentId = goal.parent?.persistentModelID,
                      let assocId = goal.association?.name,
                      let parent = budgetRelation[parentId],
                      let assoc = accountRelation[assocId] else {
                    log.warning("Unable to find the parent for entry \(goal.persistentModelID.entityName).\(String(describing: goal.persistentModelID.id)).");
                    continue;
                }
                
                self.budgetGoals[UUID()] = Self.BudgetGoal(from: goal, parent: parent, association: assoc);
            }
            
            for goal in spendingGoals {
                guard let parentId = goal.parent?.persistentModelID,
                      let assocId = goal.association?.name,
                      let parent = budgetRelation[parentId],
                      let assoc = categoryRelation[assocId] else {
                    log.warning("Unable to find the parent for entry \(goal.persistentModelID.entityName).\(String(describing: goal.persistentModelID.id)).");
                    continue;
                }
                
                self.budgetGoals[UUID()] = Self.BudgetGoal(from: goal, parent: parent, association: assoc);
            }
        }
        
        var incomeDivisionsRelation: [PersistentIdentifier : UUID] = [:];
        do {
            let incomeDivisions = try context.fetch(FetchDescriptor<EdmundCore.IncomeDivision>());
            
            self.incomeDivisions = [:];
            for division in incomeDivisions {
                guard let parentId = division.parent?.persistentModelID,
                      let accountId = division.depositTo?.name,
                      let parent = budgetRelation[parentId],
                      let account = accountRelation[accountId] else {
                    log.warning("Unable to find the parent for entry \(division.persistentModelID.entityName).\(String(describing: division.persistentModelID.id)).");
                    continue;
                }
                
                let id = UUID();
                incomeDivisionsRelation[division.persistentModelID] = id;
                self.incomeDivisions[id] = Self.IncomeDivision(from: division, parent: parent, depositTo: account);
            }
        }
        
        do {
            let amountDevotions = try context.fetch(FetchDescriptor<EdmundCore.AmountDevotion>());
            let percentDevotions = try context.fetch(FetchDescriptor<EdmundCore.PercentDevotion>());
            let remainderDevotions = try context.fetch(FetchDescriptor<EdmundCore.RemainderDevotion>());
            
            self.incomeDevotions = [:];
            
            for devotion in amountDevotions {
                guard let parentId = devotion.parent?.persistentModelID,
                      let accountId = devotion.account?.name,
                      let parent = incomeDivisionsRelation[parentId],
                      let account = accountRelation[accountId] else {
                    log.warning("Unable to find the parent for entry \(devotion.persistentModelID.entityName).\(String(describing: devotion.persistentModelID.id)).");
                    continue;
                }
                
                self.incomeDevotions[UUID()] = Self.IncomeDevotion(from: devotion, parent: parent, account: account);
            }
            
            for devotion in percentDevotions {
                guard let parentId = devotion.parent?.persistentModelID,
                      let accountId = devotion.account?.name,
                      let parent = incomeDivisionsRelation[parentId],
                      let account = accountRelation[accountId] else {
                    log.warning("Unable to find the parent for entry \(devotion.persistentModelID.entityName).\(String(describing: devotion.persistentModelID.id)).");
                    continue;
                }
                
                self.incomeDevotions[UUID()] = Self.IncomeDevotion(from: devotion, parent: parent, account: account);
            }
            
            for devotion in remainderDevotions {
                guard let parentId = devotion.parent?.persistentModelID,
                      let accountId = devotion.account?.name,
                      let parent = incomeDivisionsRelation[parentId],
                      let account = accountRelation[accountId] else {
                    log.warning("Unable to find the parent for entry \(devotion.persistentModelID.entityName).\(String(describing: devotion.persistentModelID.id)).");
                    continue;
                }
                
                self.incomeDevotions[UUID()] = Self.IncomeDevotion(from: devotion, parent: parent, account: account);
            }
        }
    }

    public var accounts: [UUID : Self.Account]; //Done
    public var categories: [UUID : Self.Category]; //Done
    public var ledgerEntries: [UUID : Self.LedgerEntry]; //Done
    public var bills: [UUID : Self.Bill]; //Done
    public var billHistories: [UUID : Self.BillDatapoint]; //Done
    public var budgets: [UUID : Self.Budget]; //Done
    public var budgetGoals: [UUID : Self.BudgetGoal]; //Done
    public var incomeDivisions: [UUID : Self.IncomeDivision]; //Done
    public var incomeDevotions: [UUID : Self.IncomeDevotion]; //Done
    public var hourlyJobs: [UUID : Self.HourlyJob]; //Done
    public var salariedJobs: [UUID : Self.SalariedJob]; //Done
}

public struct EdmundExportDocument<T> : Sendable, FileDocument where T: Sendable & Codable {
    public static var readableContentTypes: [UTType] { [.edmundExport] }
    
    private let content: T;
    
    public init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileNoSuchFile);
        }
        
        self.content = try JSONDecoder().decode(T.self, from: contents);
    }
    public init(from: T) {
        self.content = from;
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self.content);
        return FileWrapper(regularFileWithContents: data)
    }
}
