//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftUI
import Combine

/*
 /// A type that can be used to fill in dummy data for a `ModelContext`.
 public protocol ContainerDataFiller {
 /// Given the `context`, fill out the container's values.
 /// - Parameters:
 ///     - context: The `ModelContext` to insert to.
 @MainActor
 func fill(context: ModelContext) throws;
 }
 
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
    
    private init() {
        
    }
}

/// A collection of various tools used for SwiftData containers.
public struct Containers {
    /// The schema used by the containers.
    @MainActor
    private static let schema: Schema = Schema(versionedSchema: ModelsCurrentVersion.self)
    
    @MainActor
    private static func prepareContainer(loc: ContainerLocation) throws -> Container {
        let configuration: ModelConfiguration = switch loc {
            case .onDisk(let name):  .init(name, schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            case .simple:            .init(      schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            case .inMemory:          .init(      schema: schema, isStoredInMemoryOnly: true,  allowsSave: true, cloudKitDatabase: .none)
            case .cloudKit(let opt): .init(      schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: opt  )
        }
        

        let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [ configuration ])
        let undoManager = UndoManager()
        let context = ModelContext(container)
        context.undoManager = undoManager
        context.autosaveEnabled = true
        
        return .init(container: container, context: context, undo: undoManager)
    }
    
    /// Creates an in-memory `Container` instance using some `ContainerDataFiller`.
    /// - Parameters:
    ///     - using: The filler that will add blank data to the `Container` instance.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
    @MainActor
    private static func makeDebugContainer<T>(using: T) throws -> Container where T: ContainerDataFiller {
        let container = try prepareContainer(loc: .inMemory)
        
        try using.fill(context: container.context)
        
        return container
    }
    
    @MainActor
    private static var _uniqueDebugContainer: Container? = nil;
    /// A Container that can be used for testing the `UniqueEngine`.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
    @MainActor
    public static func uniqueDebugContainer() throws -> Container {
        if let container = _uniqueDebugContainer {
            return container
        }
        else {
            let result = try makeDebugContainer(using: UniqueElementsCreator())
            _uniqueDebugContainer = result
            return result
        }
    }
    
    @MainActor
    private static var _debugContainer: Container? = nil;
    /// A container that contains temporary, simple data used for showcasing.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
    @MainActor
    public static func debugContainer() throws -> Container {
        if let container = _debugContainer {
            return container
        }
        else {
            let result = try makeDebugContainer(using: DefaultDebugCreator())
            _debugContainer = result
            return result
        }
    }
    
    @MainActor
    private static var _transactionsWithSpreadContainer: Container? = nil;
    /// A model container with just transactions. it shows a spread with amounts & dates so that the UI elements can be tested.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
    @MainActor
    public static func transactionsWithSpreadContainer() throws -> Container {
        if let container = _transactionsWithSpreadContainer {
            return container
        }
        else {
            let result = try makeDebugContainer(using: TransactionSpreadCreator())
            _transactionsWithSpreadContainer = result
            return result
        }
    }
    
    @MainActor
    private static var _emptyContainer: Container? = nil;
    /// Creates an empty container stored in memory
    /// - Throws: Anything that SwiftData throws while creating the instance.
    @MainActor
    public static func emptyMemoryContainer() throws -> Container {
        if let container = _emptyContainer {
            return container
        }
        else {
            let result = try prepareContainer(loc: .inMemory)
            _emptyContainer = result
            return result
        }
    }
    
    @MainActor
    private static var _mainContainer: Container? = nil;
    /// The main container used by the app. This stores the data for the app in non-debug based contexts.
    /// - Throws: Anything that SwiftData throws while creating the instance.
    @available(*, deprecated, message: "Use file based containers instead")
    @MainActor
    public static func mainContainer() throws -> Container {
        if let container = _mainContainer {
            return container
        }
        else {
            let result = try prepareContainer(loc: .simple)
            _mainContainer = result
            return result
        }
    }
}

public struct DebugSampleData: PreviewModifier {
    public static func makeSharedContext() throws -> Container {
        return try Containers.debugContainer();
    }
    
    public func body(content: Content, context: Container) -> some View {
        content.modelContext(context.context)
    }
}

@available(macOS 15, iOS 18, *)
public extension PreviewTrait where T == Preview.ViewTraits {
    static let sampleData: Self = .modifier(DebugSampleData())
}
