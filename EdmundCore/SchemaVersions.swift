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
            
            Self.IncomeDividerInstance.self,
            Self.AmountDevotion.self,
            Self.PercentDevotion.self,
            Self.RemainderDevotion.self
        ]
    }
}

public typealias ModelsCurrentVersion = EdmundModelsV1;

public struct MigrationPlan : SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [EdmundModelsV1.self]
    }
    
    public static var stages: [MigrationStage] {
        return [
            
        ]
    }
}
