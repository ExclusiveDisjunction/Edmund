//
//  Empty.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import Foundation
import SwiftData
import SwiftUI

/// A type that can be used to fill in dummy data for a `ModelContext`.
public protocol ContainerDataFiller : Sendable {
    /// Given the `context`, fill out the container's values.
    /// - Parameters:
    ///     - context: The `ModelContext` to insert to.
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
        
        let utilities = Utility.exampleUtility;
        for utility in utilities {
            context.insert(utility)
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
        
        let utilities = Utility.exampleUtility;
        for utility in utilities {
            context.insert(utility)
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

/// A description of where a `Container` instance will be stored.
public enum ContainerLocation {
    /// Stored as the default location provided by Swift.
    case simple
    /// A container that will be stored in memory only.
    case inMemory
    /// A container that has a physical location on Disk to store at.
    case onDisk(String)
    /// A container that will be stored using CloudKit.
    case cloudKit(ModelConfiguration.CloudKitDatabase)
}

/// A resolved bundle of SwiftData needed types for the UI to bind to.
public struct Container : Sendable {
    public let container: ModelContainer
}

/// A debug tool that will automatically force open the `Containers.debugContainer`, and present some content. The content will have the model container bound to the UI's environment.
/// - Note: This is designed for use in `#Preview` expansions. It is not intended for use in the main UI.
/// - Warning: Do not use this in a release context.
public struct DebugContainerView<Content> : View where Content: View {
    /// Creates the view with an inner view.
    /// - Parameters:
    ///     - content: A closure that is used to present some `View` with the loaded debug container.
    /// - Note: This will force try the `Containers.debugContainer()` function. If that function throws unexpectedly, this will crash the program.
    /// - Warning: Do not use this in a release context.
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.container = try! Containers.debugContainer()
    }
    /// The content to present with the `ModelContext`.
    public let content: () -> Content;
    /// The resolved `Container` instance to bind to.
    public let container: Container;
    
    public var body: some View {
        content()
            .environment(\.modelContext, container.container.mainContext)
    }
}

/// A collection of various tools used for SwiftData containers.
public struct Containers {
    /// The schema used by the containers.
    private static let schema: Schema = Schema(versionedSchema: ModelsCurrentVersion.self)
    
    private static func prepareContainer(loc: ContainerLocation) throws -> Container {
        let configuration: ModelConfiguration = switch loc {
            case .onDisk(let name):  .init(name, schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            case .simple:            .init(      schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: .none)
            case .inMemory:          .init(      schema: schema, isStoredInMemoryOnly: true,  allowsSave: true, cloudKitDatabase: .none)
            case .cloudKit(let opt): .init(      schema: schema, isStoredInMemoryOnly: false, allowsSave: true, cloudKitDatabase: opt  )
        }
        

        let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [ configuration ])
        
        return .init(container: container)
    }
    
    /// Creates an in-memory `Container` instance using some `ContainerDataFiller`.
    /// - Parameters:
    ///     - using: The filler that will add blank data to the `Container` instance.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
    private static func makeDebugContainer<T>(using: T) throws -> Container where T: ContainerDataFiller {
        let container = try prepareContainer(loc: .inMemory)
        
        Task {
            let context = ModelContext(container.container);
            try using.fill(context: context)
        }
        
        return container
    }
    
    nonisolated(unsafe) private static var _uniqueDebugContainer: Container? = nil;
    /// A Container that can be used for testing the `UniqueEngine`.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
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
    
    nonisolated(unsafe)private static var _debugContainer: Container? = nil;
    /// A container that contains temporary, simple data used for showcasing.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
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
    
    
    nonisolated(unsafe) private static var _transactionsWithSpreadContainer: Container? = nil;
    /// A model container with just transactions. it shows a spread with amounts & dates so that the UI elements can be tested.
    /// - Warning: Do not use this in a release context.
    /// - Throws: Anything that SwiftData throws while creating the instance.
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
    
    nonisolated(unsafe) private static var _emptyContainer: Container? = nil;
    /// Creates an empty container stored in memory
    /// - Throws: Anything that SwiftData throws while creating the instance.
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
    
    nonisolated(unsafe) private static var _mainContainer: Container? = nil;
    /// The main container used by the app. This stores the data for the app in non-debug based contexts.
    /// - Throws: Anything that SwiftData throws while creating the instance.
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
