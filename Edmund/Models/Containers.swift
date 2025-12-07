//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
@preconcurrency import CoreData
import SwiftUI
import Combine

 /// A type that can be used to fill in dummy data for a `ModelContext`.
public protocol ContainerDataFiller {
    /// Given the `context`, fill out the container's values.
    /// - Parameters:
    ///     - context: The `ModelContext` to insert to.
    func fill(context: NSManagedObjectContext) throws;
}
 
/*
 /// A creator that is used for testing uniquness by the `UniqueEngine`.
public struct UniqueElementsCreator : ContainerDataFiller {
    public func fill(context: ModelContext) {
        let accounts = Account.exampleAccounts
        let categories = Category.exampleCategories;
        
        for account in accounts {
            context.insert(account)
        }
        for category in categories {
            context.insert(category)
        }
        
        let bills = Bill.exampleBills;
        for bill in bills {
            context.insert(bill)
        }
        
        context.insert(HourlyJob.exampleJob)
        context.insert(SalariedJob.exampleJob)
    }
}
 
 /// A creator that creates many different kinds of UI ready data.
public struct DefaultDebugCreator : ContainerDataFiller {
    public func fill(context: ModelContext) throws {
        let accounts = Account.exampleAccounts
        var accTree = try ElementLocator(data: accounts)
        
        let categories = Category.exampleCategories;
        var catTree = try ElementLocator(data: categories)
        
        for account in accounts {
            context.insert(account)
        }
        for category in categories {
            context.insert(category)
        }
        
        let bills = Bill.exampleBills;
        for bill in bills {
            context.insert(bill)
        }
        
        context.insert(HourlyJob.exampleJob)
        context.insert(SalariedJob.exampleJob)
        
        let ledger = LedgerEntry.exampleEntries(acc: &accTree, cat: &catTree)
        for entry in ledger {
            context.insert(entry);
        }
        
        let budget = BudgetMonth.exampleBudgetMonth(cat: &catTree, acc: &accTree)
        context.insert(budget)
        
        context.insert(IncomeDivision.exampleDivision(acc: &accTree))
    }
}
 /// A creator that creates transactions that are spread out so that graphs can be tested.
public struct TransactionSpreadCreator : ContainerDataFiller {
    public func fill(context: ModelContext) {
        let account = Account("Test Account")
        let category = Category("Test Category")
        
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
 */

public class DataStack : ObservableObject, @unchecked Sendable {
    public static let shared: DataStack = DataStack()
    
    private var _persistentContainer: NSPersistentContainer? = nil;
    private var _debugContainer: NSPersistentContainer? = nil;

    public var persistentContainer: NSPersistentContainer {
        get {
            if let container = self._persistentContainer {
                return container;
            }
            
            let container = NSPersistentContainer(name: "EdmundDataModel");
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError("Unable to load persistent store due to error \(error)")
                }
            }
            
            self._persistentContainer = container;
            return container;
        }
    }
    
    public var debugContainer: NSPersistentContainer {
        get {
            if let container = self._debugContainer {
                return container;
            }
            
            let container = NSPersistentContainer(name: "debugContainer");
            
            let desc = NSPersistentStoreDescription();
            desc.type = NSInMemoryStoreType;
            desc.shouldAddStoreAsynchronously = false;
            container.persistentStoreDescriptions = [desc]
            
            container.loadPersistentStores { desc, error in
                if let error = error {
                    fatalError("Failed to make in memory store: \(error)")
                }
                
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.perform {
                    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
                }
            }
            
            _debugContainer = container;
            return container
        }
    }
    
    private init() {
        
    }
}

public struct DebugSampleData: PreviewModifier {
    public static func makeSharedContext() throws -> DataStack {
        DataStack.shared
    }
    
    public func body(content: Content, context: DataStack) -> some View {
        content
            .environment(\.managedObjectContext, context.persistentContainer.viewContext)
    }
}

@available(macOS 15, iOS 18, *)
public extension PreviewTrait where T == Preview.ViewTraits {
    static let sampleData: Self = .modifier(DebugSampleData())
}
