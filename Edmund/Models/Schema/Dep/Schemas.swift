//
//  Schemas.swift
//  EdmundPro
//
//  Created by Hollan Sellars on 10/9/25.
//

import SwiftData

public enum EdmundModelsV1_1 : VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    
    public static var models: [any PersistentModel.Type] {
        [
            Self.LedgerEntry.self,
            Self.Account.self,
            Self.Category.self,
            
            Self.Bill.self,
            Self.BillDatapoint.self,
            
            Self.HourlyJob.self,
            Self.SalariedJob.self,
            
            Self.IncomeDivision.self,
            Self.IncomeDevotion.self,
            
            Self.BudgetMonth.self,
            Self.BudgetSavingsGoal.self,
            Self.BudgetSpendingGoal.self
        ]
    }
}

public struct MigrationPlan : SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            EdmundModelsV1_1.self
        ]
    }
    
    public static var stages: [MigrationStage] {
        []
    }
}


public typealias ModelsCurrentVersion = EdmundModelsV1_1;

public typealias Bill = ModelsCurrentVersion.Bill;
public typealias BillDatapoint = ModelsCurrentVersion.BillDatapoint;

public typealias Account = ModelsCurrentVersion.Account;
public typealias Category = ModelsCurrentVersion.Category;

public typealias IncomeDivision = ModelsCurrentVersion.IncomeDivision;
public typealias IncomeDevotion = ModelsCurrentVersion.IncomeDevotion;

public typealias BudgetMonth = ModelsCurrentVersion.BudgetMonth;
public typealias BudgetSpendingGoal = ModelsCurrentVersion.BudgetSpendingGoal;
public typealias BudgetSavingsGoal = ModelsCurrentVersion.BudgetSavingsGoal;

public typealias HourlyJob = ModelsCurrentVersion.HourlyJob;
public typealias SalariedJob = ModelsCurrentVersion.SalariedJob;

public typealias LedgerEntry = ModelsCurrentVersion.LedgerEntry;
