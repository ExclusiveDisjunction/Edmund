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

public func ver1ToVer1_1(context: ModelContext) throws {
    print("Performing migrations.")
    //First we fetch all categories and accounts.
    let oldAccounts = try context.fetch(FetchDescriptor<EdmundModelsV1.Account>());
    let oldCategories = try context.fetch(FetchDescriptor<EdmundModelsV1.Category>());
    
    let newAccounts = oldAccounts.map {
        let result = EdmundModelsV1_1.Account(migration: $0);
        context.insert(result);
        return result;
    };
    let newCategories = oldCategories.map {
        let result = EdmundModelsV1_1.Category(migration: $0)
        context.insert(result);
        return result;
    };
    
    //Now we can build a tree for later use
    var accountsTree = try ElementLocator(data: newAccounts);
    var categoriesTree = try ElementLocator(data: newCategories);
    
    // Migrate ledger entries:
    // Move from sub account holder to account holder
    // If the sub account or sub category is nil, skip the transaction.
    let oldLedger = try context.fetch(FetchDescriptor<EdmundModelsV1.LedgerEntry>());
    for oldElement in oldLedger {
        guard let subAcc = oldElement.account, let oldAcc = subAcc.parent,
              let subCat = oldElement.category, let oldCat = subCat.parent else {
            continue;
        }
        
        let newAcc = accountsTree.getOrInsert(name: oldAcc.name);
        let newCat = categoriesTree.getOrInsert(name: oldCat.name);
        
        context.insert(
            EdmundModelsV1_1.LedgerEntry(migration: oldElement, category: newCat, account: newAcc)
        )
    }
    
    let oldBills = try context.fetch(FetchDescriptor<EdmundModelsV1.Bill>());
    for oldBill in oldBills {
        context.insert(
            EdmundModelsV1_1.Bill(migrate: oldBill)
        )
    }
    let oldUtilities = try context.fetch(FetchDescriptor<EdmundModelsV1.Utility>());
    for oldUtility in oldUtilities {
        context.insert(
            EdmundModelsV1_1.Utility(migrate: oldUtility)
        )
    }
    
    let oldHourly = try context.fetch(FetchDescriptor<EdmundModelsV1.HourlyJob>());
    for job in oldHourly {
        context.insert(
            EdmundModelsV1_1.HourlyJob(migration: job)
        )
    }
    let oldSalary = try context.fetch(FetchDescriptor<EdmundModelsV1.SalariedJob>());
    for job in oldSalary {
        context.insert(
            EdmundModelsV1_1.SalariedJob(migration: job)
        )
    }
    
    let oldBudget = try context.fetch(FetchDescriptor<EdmundModelsV1.BudgetMonth>());
    for budget in oldBudget {
        let newBudget = EdmundModelsV1_1.BudgetMonth(migrate: budget);
        for oldSpending in budget.spendingGoals {
            guard let subCat = oldSpending.association, let oldCat = subCat.parent else {
                continue;
            }
            
            let newCat = categoriesTree.getOrInsert(name: oldCat.name);
            newBudget.spendingGoals.append(
                EdmundModelsV1_1.BudgetSpendingGoal(category: newCat, amount: oldSpending.amount, period: .monthly, parent: newBudget)
            )
        }
        
        for oldSavings in budget.savingsGoals {
            guard let subAcc = oldSavings.association, let oldAcc = subAcc.parent else {
                continue;
            }
            
            let newAcc = accountsTree.getOrInsert(name: oldAcc.name);
            newBudget.savingsGoals.append(
                EdmundModelsV1_1.BudgetSavingsGoal(account: newAcc, amount: oldSavings.amount, period: .monthly, parent: newBudget)
            )
        }
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
            .custom(fromVersion: EdmundModelsV1.self, toVersion: EdmundModelsV1_1.self, willMigrate: nil, didMigrate: ver1ToVer1_1)
        ]
    }
}
