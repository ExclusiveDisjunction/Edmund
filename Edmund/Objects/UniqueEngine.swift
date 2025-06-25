//
//  IDRegistry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// A quick overview of a property used to uniqueley identify a`UniqueElement`.
public struct ElementIdentifer : Identifiable, Equatable {
    public init(name: LocalizedStringKey, optional: Bool = false, id: UUID = UUID()) {
        self.id = id;
        self.name = name
        self.optional = optional
    }
    
    public var id: UUID;
    /// The name of the property. For example, 'Name'.
    public var name: LocalizedStringKey;
    /// If this type is optional or not. If it is optional, that means the value can be ommited from the owning type.
    public var optional: Bool;
    
    public static func == (lhs: ElementIdentifer, rhs: ElementIdentifer) -> Bool {
        lhs.name == rhs.name && lhs.optional == rhs.optional
    }
}

/// A protocol that determines if an element is unique.
/// For the unique pattern to work, the type must implement this protocol.
public protocol UniqueElement: Identifiable {
    /// A list of properties used to identify the data as unique.
    /// When an error about uniqueness is presented, the UI will include these values.
    static var identifiers: [ElementIdentifer] { get }
    
    func removeFromEngine(unique: UniqueEngine) -> Bool;
}

/// A struct that allows for the access of all unique elements out of a modelContext in a safe way.
public struct RegistryData {
    /// Extracts the required information out of the `context`, running on the main thread.
    /// - Parameters:
    ///     - context: The `ModelContext` to extract information from.
    /// - Throws:
    ///     - Any error that the context will throw when fetching the required information.
    @MainActor
    public init(_ context: ModelContext) throws {
        self.acc =      try context.fetch(FetchDescriptor<Account>    ());
        self.subAcc =   try context.fetch(FetchDescriptor<SubAccount> ());
        self.cat =      try context.fetch(FetchDescriptor<Category>   ());
        self.subCat =   try context.fetch(FetchDescriptor<SubCategory>());
        let  bills =    try context.fetch(FetchDescriptor<Bill>       ());
        let  utility =  try context.fetch(FetchDescriptor<Utility>    ());
        let  hourly =   try context.fetch(FetchDescriptor<HourlyJob>  ());
        let  salaried = try context.fetch(FetchDescriptor<SalariedJob>());
        
        self.allBills = (bills as [any BillBase]) + (utility as [any BillBase]);
        self.allJobs =  (hourly as [any TraditionalJob]) + (salaried as [any TraditionalJob]);
    }
    
    /// All accounts in the context.
    public let acc: [Account];
    /// All sub accounts in the context.
    public let subAcc: [SubAccount];
    /// All categories in the context.
    public let cat: [Category];
    /// All sub categories in the context.
    public let subCat: [SubCategory];
    /// All bills & utilities in the context.
    public let allBills: [any BillBase];
    /// All hourly & salaried jobs in the context.
    public let allJobs: [any TraditionalJob];
}

/// A specific lightweight action to instruct the `UniqueEngine` to perform some action.
public enum UniqueEngineAction {
    /// Instructs the engine to determine that ID is taken.
    case validate
    //// Instructs the engine to reserve that ID
    case insert
    /// Instructs the engine to de-reserve that ID
    case remove
}

/// An error that occurs when the unique engine cannot validate a claim to an ID, but was assumed to be a free value.
public struct UniqueFailueError<T> : Error where T: Sendable, T: Hashable {
    /// The ID that was taken already
    public let value: T
    
    /// A description of what happened
    public var description: String {
        "A uniqueness check failed for identifier \(value)"
    }
    public var localizedDescription: LocalizedStringKey {
        "The uniqueness constraint failed for this value. Please cancel the edit and try again."
    }
}

/// An environment safe class that can be used to enforce the uniqueness amongts different objects of the same type.
@Observable
public final class UniqueEngine {
    /// Creates the engine with empty sets.
    public init() {
        self.accounts = .init();
        self.subAccounts = .init();
        self.categories = .init();
        self.subCategories = .init();
        self.allBills = .init();
        self.allJobs = .init();
    }
    /// Creates the engine with data from a `ModelContext`.
    /// This will fill all sets with the currently taken IDs.
    public init(_ data: RegistryData) {
        self.accounts = Set(data.acc.map { $0.id })
        self.subAccounts = Set(data.subAcc.map { $0.id })
        self.categories = Set(data.cat.map { $0.id } )
        self.subCategories = Set(data.subCat.map { $0.id } )
        self.allBills = Set(data.allBills.map { $0.id } )
        self.allJobs = Set(data.allJobs.map { $0.id } )
    }
    
    /// The taken account IDs.
    private var accounts: Set<Account.ID>;
    /// The taken sub account IDs.
    private var subAccounts: Set<SubAccount.ID>;
    /// The taken category IDs.
    private var categories: Set<Category.ID>;
    /// The taken sub category IDs.
    private var subCategories: Set<SubCategory.ID>;
    /// The taken bills & utilities IDs.
    private var allBills: Set<BillBaseID>;
    /// The taken hourly & salaried job IDs.
    private var allJobs: Set<TraditionalJobID>;
    
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    private static func perform<T>(id: T, set: inout Set<T>, action: UniqueEngineAction) -> Bool where T: Hashable {
        switch action {
            case .insert:   set.insert(id).inserted
            case .validate: !set.contains(id)
            case .remove:   set.remove(id) != nil
        }
    }
    
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    public func account(id: Account.ID, action: UniqueEngineAction) -> Bool {
        Self.perform(id: id, set: &accounts, action: action)
    }
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    public func subAccount(id: SubAccount.ID, action: UniqueEngineAction) -> Bool {
        Self.perform(id: id, set: &subAccounts, action: action)
    }
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    public func category(id: Category.ID, action: UniqueEngineAction) -> Bool {
        Self.perform(id: id, set: &categories, action: action)
    }
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    public func subCategory(id: SubCategory.ID, action: UniqueEngineAction) -> Bool {
        Self.perform(id: id, set: &subCategories, action: action)
    }
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    public func bill(id: BillBaseID, action: UniqueEngineAction) -> Bool {
        Self.perform(id: id, set: &allBills, action: action)
    }
    /// Performs a specific `UniqueEngineAction` on the specified ID, and returns the result.
    public func job(id: TraditionalJobID, action: UniqueEngineAction) -> Bool {
        Self.perform(id: id, set: &allJobs, action: action)
    }
}

/// The key used to store the `UniqueEngine` in `EnvironmentValues`.
private struct UniqueEngineKey: EnvironmentKey {
    static let defaultValue: UniqueEngine = .init();
}

public extension EnvironmentValues {
    /// A global value for the unique engine. This will always exist.
    var uniqueEngine: UniqueEngine {
        get { self[UniqueEngineKey.self] }
        set { self[UniqueEngineKey.self] = newValue }
    }
}
