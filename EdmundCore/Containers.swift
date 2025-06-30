//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData

public protocol ExampleCreator {
    @MainActor
    func fill(context: ModelContext) throws;
}

public struct DefaultDebugCreator : ExampleCreator {
    public func fill(context: ModelContext) {
        let accounts = Account.exampleAccounts
        for account in accounts {
            context.insert(account)
        }
        let categories = Category.exampleCategories;
        for category in categories {
            context.insert(category)
        }
        
        let bills = Bill.exampleBills;
        for bill in bills {
            context.insert(bill)
        }
        
        let utilities = Utility.exampleUtility;
        for utility in utilities {
            context.insert(utility)
        }
        
        context.insert(HourlyJob.exampleJob)
        context.insert(SalariedJob.exampleJob)
        
        var accTree = BoundPairTree(data: accounts)
        var catTree = BoundPairTree(data: categories)
        
        let ledger = LedgerEntry.exampleEntries(acc: &accTree, cat: &catTree)
        for entry in ledger {
            context.insert(entry);
        }
        
        context.insert(BudgetInstance.exampleBudget(acc: &accTree))
    }
}
public struct TransactionSpreadCreator : ExampleCreator {
    public func fill(context: ModelContext) {
        let account = SubAccount("Test Sub Account", parent: .init("Test Account"))
        let category = SubCategory("Test Sub Category", parent: .init("Test Category"))
        
        context.insert(account)
        context.insert(category)
        
        let transactions: [LedgerEntry] = [
            .init(name: "", credit: 100, debit: 0, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 100, debit: 0, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 200, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 1, 1)!, location: "", category: category, account: account),
            
            .init(name: "", credit: 0, debit: 100, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 100, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 400, debit: 0, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 100, date: Date.fromParts(2025, 2, 1)!, location: "", category: category, account: account),
            
            .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 500, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 200, debit: 0, date: Date.fromParts(2025, 3, 1)!, location: "", category: category, account: account),
            
            .init(name: "", credit: 0, debit: 300, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 300, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 100, debit: 0, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
            .init(name: "", credit: 0, debit: 300, date: Date.fromParts(2025, 4, 1)!, location: "", category: category, account: account),
        ];
        
        for trans in transactions {
            context.insert(trans)
        }
    }
}

public enum ContainerLocation {
    case simple
    case inMemory
    case onDisk(String)
    case cloudKit(ModelConfiguration.CloudKitDatabase)
}

/// A collection of various tools used for SwiftData containers.
public struct Containers {
    public static let interestedTypes: [any PersistentModel.Type] = [
        LedgerEntry.self,
        Account.self,
        SubAccount.self,
        
        Category.self,
        SubCategory.self,
        
        Bill.self,
        Utility.self,
        UtilityEntry.self,
        
        HourlyJob.self,
        SalariedJob.self,
        
        BudgetInstance.self,
        AmountDevotion.self,
        PercentDevotion.self,
        RemainderDevotion.self
    ]
    
    /// The schema used by the containers.
    @MainActor
    private static let schema: Schema = .init(interestedTypes)
    
    @MainActor
    private static func prepareContainer(loc: ContainerLocation) throws -> ModelContainer {
        let configuration: ModelConfiguration = switch loc {
            case .onDisk(let name):  .init(name, schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            case .simple:            .init(      schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            case .inMemory:          .init(      schema: schema, isStoredInMemoryOnly: true,  allowsSave: true, cloudKitDatabase: .none)
            case .cloudKit(let opt): .init(      schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: opt  )
        }
        

        let result = try ModelContainer(for: schema, configurations: [ configuration ])
        result.mainContext.undoManager = UndoManager()
        result.mainContext.autosaveEnabled = true;
        
        return result;
    }
    
    @MainActor
    private static func makeDebugContainer<T>(using: T) throws -> ModelContainer where T: ExampleCreator {
        let container = try prepareContainer(loc: .inMemory)
        let context = container.mainContext
        
        try using.fill(context: context)
        
        return container
    }
    
    /// A container that contains temporary, simple data used for showcasing.
    @MainActor
    public static func debugContainer() throws -> ModelContainer {
         try makeDebugContainer(using: DefaultDebugCreator())
    }
    
    /// A model container with just transactions. it shows a spread with amounts & dates so that the UI elements can be tested.
    @MainActor
    public static func transactionsWithSpreadContainer() throws -> ModelContainer {
        try makeDebugContainer(using: TransactionSpreadCreator())
    }
    
    /// The main container used by the app. This stores the data for the app in non-debug based contexts. 
    @MainActor
    public static func mainContainer() throws -> ModelContainer {
        try prepareContainer(loc: .simple)
    }
}
