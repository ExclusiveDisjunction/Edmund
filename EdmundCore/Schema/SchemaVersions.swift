//
//  SchemaVersions.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftData

public enum EdmundModelsV1 : VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    
    public static var models: [any PersistentModel.Type] {
        return [
            Self.LedgerEntry.self,
            Self.Account.self,
            Self.SubAccount.self,
            
            Self.Category.self,
            Self.SubCategory.self,
            
            Self.Bill.self,
            Self.Utility.self,
            Self.UtilityDatapoint.self,
            
            Self.HourlyJob.self,
            Self.SalariedJob.self,
            
            Self.IncomeDivision.self,
            Self.AmountDevotion.self,
            Self.PercentDevotion.self,
            Self.RemainderDevotion.self,
            
            Self.BudgetMonth.self,
            Self.BudgetSavingsGoal.self,
            Self.BudgetSpendingGoal.self,
            Self.BudgetIncome.self
        ]
    }
}

public enum EdmundModelsV1_1 : VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 1, 0) }
    
    public static var models: [any PersistentModel.Type] {
        [
            Self.LedgerEntry.self,
            Self.Account.self,
            Self.SubAccount.self,
            
            Self.Category.self,
            Self.SubCategory.self,
            
            Self.Bill.self,
            Self.Utility.self,
            Self.UtilityDatapoint.self,
            
            Self.HourlyJob.self,
            Self.SalariedJob.self,
            
            Self.IncomeDivision.self,
            Self.AmountDevotion.self,
            Self.PercentDevotion.self,
            Self.RemainderDevotion.self,
            
            Self.BudgetMonth.self,
            Self.BudgetSavingsGoal.self,
            Self.BudgetSpendingGoal.self,
            Self.BudgetIncome.self
        ]
    }
}

struct V1AllData {
    init(context: ModelContext) throws {
        
    }
    
    let ledger: [LedgerEntry];
    let account: [Account];
    let category: [Category];
    let bills: [Bill];
    let utilities: [Utility];
    let hourlyJob: [HourlyJob];
    let salariedJob: [SalariedJob];
    let incomeDivisions: [IncomeDivision];
    let budgets: [BudgetMonth];
}


struct V1toV1_1Migration {
    init(context: ModelContext) throws {
        
    }
}

public struct MigrationPlan : SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            EdmundModelsV1.self,
            EdmundModelsV1_1.self
        ]
    }
    
    public static var stages: [MigrationStage] {
        return [
            .custom(fromVersion: EdmundModelsV1.self, toVersion: EdmundModelsV1_1.self, willMigrate: nil, didMigrate: { context in
                
            })
        ]
    }
}
