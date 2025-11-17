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
            Self.LedgerEntry.self, //Migrated
            Self.Account.self, //Migrated
            Self.Category.self, //Migrated
            
            Self.Bill.self, //Migrated
            Self.BillDatapoint.self, //No migration needed
            Self.Utility.self, //Migrated
            Self.UtilityDatapoint.self, //Migrated
            
            Self.HourlyJob.self, //Migrated
            Self.SalariedJob.self, //Migrated
            
            Self.IncomeDivision.self, // Deleted in migration
            Self.AmountDevotion.self, // Deleted in migration
            Self.PercentDevotion.self, // Deleted in migration
            Self.RemainderDevotion.self, // Deleted in migration
            
            Self.BudgetMonth.self, //Migrated
            Self.BudgetSavingsGoal.self, //Migrated
            Self.BudgetSpendingGoal.self //Migrated
        ]
    }
}

public enum EdmundModelsV2 : VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    
    public static var models: [any PersistentModel.Type] {
        [
            Self.LedgerEntry.self, //Migrated
            Self.Account.self, //Migrated
            Self.Category.self, //Migrated
            
            Self.Bill.self, //Migrated
            Self.BillDatapoint.self, //No migration needed
            
            Self.HourlyJob.self, //Migrated
            Self.SalariedJob.self, //Migrated
            
            Self.IncomeDivision.self, // Deleted in migration
            Self.IncomeDevotion.self, // Deleted in migration
            
            Self.BudgetMonth.self, //Migrated
            Self.BudgetSavingsGoal.self, //Migrated
            Self.BudgetSpendingGoal.self //Migrated
        ]
    }
}

public struct MigrationPlan : SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            EdmundModelsV1.self,
            EdmundModelsV1_1.self,
            EdmundModelsV2.self,
        ]
    }
    
    public static var stages: [MigrationStage] {
        return [
            .custom(fromVersion: EdmundModelsV1.self, toVersion: EdmundModelsV1_1.self, willMigrate: { _ in fatalError() }, didMigrate: { _ in fatalError() }),
            .custom(fromVersion: EdmundModelsV1_1.self, toVersion: EdmundModelsV1.self, willMigrate: { _ in fatalError() }, didMigrate: { _ in fatalError() })
        ]
    }
}
