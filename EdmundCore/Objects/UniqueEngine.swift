//
//  IDRegistry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import Foundation
import SwiftUI
import SwiftData

/// A struct that allows for the access of all unique elements out of a modelContext in a safe way.
public struct RegistryData {
    /// Extracts the required information out of the `context`, running on the main thread.
    /// - Parameters:
    ///     - context: The `ModelContext` to extract information from.
    /// - Throws:
    ///     - Any error that the context will throw when fetching the required information.
    @MainActor
    public init(_ context: ModelContext) throws {
        self.acc =      try context.fetch(FetchDescriptor<Account>            ());
        self.subAcc =   try context.fetch(FetchDescriptor<SubAccount>         ());
        self.cat =      try context.fetch(FetchDescriptor<EdmundCore.Category>());
        self.subCat =   try context.fetch(FetchDescriptor<SubCategory>        ());
        let  bills =    try context.fetch(FetchDescriptor<Bill>               ());
        let  utility =  try context.fetch(FetchDescriptor<Utility>            ());
        let  hourly =   try context.fetch(FetchDescriptor<HourlyJob>          ());
        let  salaried = try context.fetch(FetchDescriptor<SalariedJob>        ());
        
        self.allBills = (bills as [any BillBase]) + (utility as [any BillBase]);
        self.allJobs =  (hourly as [any TraditionalJob]) + (salaried as [any TraditionalJob]);
    }
    
    /// All accounts in the context.
    public let acc: [Account];
    /// All sub accounts in the context.
    public let subAcc: [SubAccount];
    /// All categories in the context.
    public let cat: [EdmundCore.Category];
    /// All sub categories in the context.
    public let subCat: [SubCategory];
    /// All bills & utilities in the context.
    public let allBills: [any BillBase];
    /// All hourly & salaried jobs in the context.
    public let allJobs: [any TraditionalJob];
}

/// An environment safe class that can be used to enforce the uniqueness amongts different objects of the same type.
@Observable
public class UniqueEngine {
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
    public var accounts: Set<String>;
    /// The taken sub account IDs.
    public var subAccounts: Set<String>;
    /// The taken category IDs.
    public var categories: Set<String>;
    /// The taken sub category IDs.
    public var subCategories: Set<String>;
    /// The taken bills & utilities IDs.
    public var allBills: Set<String>;
    /// The taken hourly & salaried job IDs.
    public var allJobs: Set<String>;
    
    /// Registers the item into a set if its not already contained.
    /// - Parameters:
    ///     - set: The set to modify
    ///     - new: The new value to register
    /// - Returns:
    ///     - `true` if the element was not in the set, `false` otherwise. If it was not previously contained, it will be contained after this function completes.
    private static func registerInto<T>(_ set: inout Set<T>, _ new: T) -> Bool where T: Hashable{
        guard !set.contains(new) else {
            return false;
        }
        
        set.insert(new);
        return true;
    }
    private static func deregisterInto<T>(_ set: inout Set<T>, _ id: T) where T: Hashable {
        set.remove(id);
    }
    
    // Checks if the ID for an account is ok. If this returns false, it is already taken.
    public func checkAccount(_ id: String) -> Bool {
        !accounts.contains(id)
    }
    // Checks if the ID for a sub account is ok. If this returns false, it is already taken.
    public func checkSubAccount(_ id: String) -> Bool {
        !subAccounts.contains(id)
    }
    
    // Checks if the ID for a category is ok. If this returns false, it is already taken.
    public func checkCategory(_ id: String) -> Bool {
        !categories.contains(id)
    }
    // Checks if the ID for a sub category is ok. If this returns false, it is already taken.
    public func checkSubCategory(_ id: String) -> Bool {
        !subCategories.contains(id)
    }
    
    // Checks if the ID for a bill or utility is ok. If this returns false, it is already taken.
    public func checkBill(_ id: String) -> Bool {
        !allBills.contains(id)
    }
    // Checks if the ID for a hourly or salaried job is ok. If this returns false, it is already taken.
    public func checkJob(_ id: String) -> Bool {
        !allJobs.contains(id)
    }

    
    /// Registers an account ID.
    public func registerAccount(_ new: String) -> Bool {
        Self.registerInto(&accounts, new)
    }
    /// Registers a sub account ID.
    public func registerSubAccount(_ new: String) -> Bool {
        Self.registerInto(&subAccounts, new)
    }
    
    /// Registers a category ID.
    public func registerCategory(_ new: String) -> Bool {
        Self.registerInto(&categories, new)
    }
    /// Registers a sub category ID.
    public func registerSubCategory(_ new: String) -> Bool {
        Self.registerInto(&subCategories, new)
    }
    
    /// Registers a bill/utility ID.
    public func registerBill(_ new: String) -> Bool {
        Self.registerInto(&allBills, new)
    }
    /// Registers a hourly / salaried job ID.
    public func registerJob(_ new: String) -> Bool {
        Self.registerInto(&allJobs, new)
    }
    
    /// De-registers an account ID.
    public func deregisterAccount(_ id: String) {
        Self.deregisterInto(&accounts, id)
    }
    /// De-registers a sub account ID.
    public func deregisterSubAccount(_ id: String) {
        Self.deregisterInto(&subAccounts, id)
    }
    
    /// De-registers a category ID.
    public func deregisterCategory(_ id: String) {
        Self.deregisterInto(&categories, id)
    }
    /// De-registers a sub category ID.
    public func deregisterSubCategory(_ id: String) {
        Self.deregisterInto(&subCategories, id)
    }
    
    /// De-registers a bill/utility ID.
    public func deregisterBill(_ id: String) {
        Self.deregisterInto(&allBills, id)
    }
    /// De-registers a hourly / salaried job ID.
    public func deregisterJob(_ id: String) {
        Self.deregisterInto(&allJobs, id)
    }
}

private struct UniqueEngineKey: EnvironmentKey {
    static let defaultValue: UniqueEngine = .init();
}

public extension EnvironmentValues {
    var uniqueEngine: UniqueEngine {
        get { self[UniqueEngineKey.self] }
        set { self[UniqueEngineKey.self] = newValue }
    }
}
