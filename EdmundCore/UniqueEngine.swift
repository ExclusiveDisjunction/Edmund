//
//  IDRegistry.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/11/25.
//

import Foundation
import SwiftUI
import SwiftData
import os

/// A protocol that determines if an element is unique.
/// For the unique pattern to work, the type must implement this protocol.
public protocol UniqueElement: Identifiable where Self.ID: Sendable {
    static var objId: ObjectIdentifier { get }
}
public extension UniqueElement {
    func getObjectId() -> ObjectIdentifier {
        Self.objId
    }
}

/// A struct that allows for the access of all unique elements out of a modelContext in a safe way.
public struct UniqueContext {
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

/// An error that occurs when the unique engine cannot validate a claim to an ID, but was assumed to be a free value.
public struct UniqueFailureError<T> : Error where T: Sendable, T: Hashable {
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
public actor UniqueEngine {
    /// Creates the engine with empty sets.
    public init(_ logger: Logger? = nil) {
        self.data = .init();
        self.logger = logger;
    }
    
    private var logger: Logger?;
    private var data: Dictionary<ObjectIdentifier, Set<AnyHashable>>;
    
    private struct DataBundle : @unchecked Sendable {
        let inner: [ObjectIdentifier : Set<AnyHashable>]
    }
    
    /// Creates the engine with data from a `UniqueContext`.
    /// This will fill all sets with the currently taken IDs.
    /// Note that this function will crash the program if any ID is non-unique.
    @MainActor
    public func fill(_ using: UniqueContext) async {
        await logger?.info("The UniqueEngine is importing from the ModelContainer.")
        let allSets: [(ObjectIdentifier, Set<AnyHashable>)] = [
            ( ObjectIdentifier(Account.self),              Set(using.acc.map      { AnyHashable($0.id) } ) ),
            ( ObjectIdentifier(SubAccount.self),           Set(using.subAcc.map   { AnyHashable($0.id) } ) ),
            ( ObjectIdentifier(Category.self),             Set(using.cat.map      { AnyHashable($0.id) } ) ),
            ( ObjectIdentifier(SubCategory.self),          Set(using.subCat.map   { AnyHashable($0.id) } ) ),
            ( ObjectIdentifier((any BillBase).self),       Set(using.allBills.map { AnyHashable($0.id) } ) ),
            ( ObjectIdentifier((any TraditionalJob).self), Set(using.allJobs.map  { AnyHashable($0.id) } ) )
        ];
        
        let dict = Dictionary(uniqueKeysWithValues: allSets);
        let wrapper = DataBundle(inner: dict)
        await self.setData(data: wrapper)
        await logger?.info("The UniqueEngine's import is complete.")
    }
    public func reset() {
        self.data = [:]
    }
    
    private func setData(data: DataBundle) async {
        self.data = data.inner
    }
    
    /// Determines if a specific ID (presumed to be from type `T`), is not being used.
    public func isIdOpen<T, ID>(type: T.Type, id: ID) async -> Bool where ID: Hashable, ID: Sendable {
        await self.isIdOpen(key: ObjectIdentifier(type), id: id)
    }
    /// Determines if a specific ID (attached to an object ID) is not being used.
    public func isIdOpen<ID>(key: ObjectIdentifier, id: ID) async -> Bool where ID: Hashable, ID: Sendable {
        !data[key, default: .init()].contains(id)
    }
    
    /// Determines if a specific ID (presumed to be from type `T`), is being used.
    public func isIdTaken<T, ID>(type: T.Type, id: ID) async -> Bool where ID: Hashable, ID: Sendable {
        await self.isIdTaken(key: ObjectIdentifier(type), id: id)
    }
    /// Determines if a specific ID (attached to an object ID) is  being used.
    public func isIdTaken<ID>(key: ObjectIdentifier, id: ID) async -> Bool where ID: Hashable, ID: Sendable {
        data[key, default: .init()].contains(id)
    }
    
    /// Attempts to reserve an ID for a specific type.
    public func reserveId<T, ID>(type: T.Type, id: ID) async -> Bool where ID: Hashable, ID: Sendable {
        await self.reserveId(key: ObjectIdentifier(type), id: id)
    }
    /// Attempts to reserve an ID for a specific object ID.
    public func reserveId<ID>(key: ObjectIdentifier, id: ID) async -> Bool where ID: Hashable, ID: Sendable {
        let result = data[key, default: .init()].insert(id).inserted
        if !result {
            logger?.error("Reserveration of id \("\(id)", privacy: .public) is already taken.")
        }
        // Since `inserted` will be false if the insert fails, this reserve call will also fail.
        return result
    }
    
    /// Attempts to release an ID from a type's pool.
    @discardableResult
    public func releaseId<T, ID>(type: T.Type, id: ID) async -> Bool where ID: Hashable, ID: Sendable  {
        await self.releaseId(key: ObjectIdentifier(type), id: id)
    }
    /// Attempts to release an ID from an object ID's pool.
    @discardableResult
    public func releaseId<ID>(key: ObjectIdentifier, id: ID) async -> Bool where ID: Hashable, ID: Sendable  {
        data[key]?.remove(id) != nil
    }
    
    /// Releases and then attempts to obtain a new ID for a specific type.
    public func swapId<T, ID>(type: T.Type, oldId: ID, newId: ID) async -> Bool where ID: Hashable, ID: Sendable {
        await self.swapId(key: ObjectIdentifier(type), oldId: oldId, newId: newId)
    }
    /// Releases and then attempts to obtain a new ID for a specific object ID.
    public func swapId<ID>(key: ObjectIdentifier, oldId: ID, newId: ID) async -> Bool where ID: Hashable, ID: Sendable {
        let _ = await self.releaseId(key: key, id: oldId)
        return await self.reserveId(key: key, id: newId)
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
