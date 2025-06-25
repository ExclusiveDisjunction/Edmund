//
//  SubAccount.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/20/25.
//

import SwiftUI
import SwiftData

/// Represents a sub-section under an account for transaction grouping.
@Model
public final class SubAccount : BoundPair, Equatable, NamedEditableElement, NamedInspectableElement, UniqueElement, TransactionHolder {
    public typealias EditView = BoundPairChildEdit<SubAccount>
    public typealias Snapshot = SubAccountSnapshot;
    public typealias InspectorView = BoundPairChildInspect<SubAccount>;
    
    public convenience init() {
        self.init("")
    }
    public convenience init(parent: Account?) {
        self.init("", parent: parent)
    }
    /// Creates the sub account with a specified name, parent account, and a list of transactions.
    public init(_ name: String, parent: Account? = nil, transactions: [LedgerEntry] = []) {
        self.name = name
        self.parent = parent
        self.transactions = transactions
    }
    
    public var id: BoundPairID {
        .init(parent: self.parentName, name: self.name)
    }
    public var name: String = "";
    @Relationship
    public var parent: Account? = nil;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account)
    public var transactions: [LedgerEntry]? = nil;
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Sub Account",
            plural:   "Sub Accounts",
            inspect:  "Inspect Sub Account",
            edit:     "Edit Sub Account",
            add:      "Add Sub Account"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Parent Name", optional: true), .init(name: "Name") ]
    }

    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.subAccount(id: self.id, action: .remove)
    }
    
    public static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    
    /// An example sub account
    public static var exampleSubAccount: SubAccount {
        .init("DI", parent: .init("Checking"))
    }
}

/// The snapshot type for `SubAccount`.
@Observable
public final class SubAccountSnapshot: ElementSnapshot, BoundPairSnapshot {
    public typealias Host = SubAccount;
    public typealias Parent = Account;
    
    public init() {
        self.name = "";
        self.parent = nil;
    }
    public init(_ from: SubAccount) {
        self.name = from.name;
        self.parent = from.parent
    }
    
    /// The sub-account's name
    public var name: String;
    /// The sub-account's parent account
    public var parent: Account?;
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result: [ValidationFailure] = [];
        
        let name = name.trimmingCharacters(in: .whitespaces);
        let id = BoundPairID(parent: parent?.name, name: name)
        
        if !unique.subAccount(id: id, action: .validate) { result.append(.unique(SubAccount.identifiers)) }
        if name.isEmpty { result.append(.empty("Name")) }
        if parent == nil { result.append(.empty("Account")) }
        
        return result;
    }
    public func apply(_ to: SubAccount, context: ModelContext, unique: UniqueEngine) throws(UniqueFailueError<BoundPairID>) {
        let name = self.name.trimmingCharacters(in: .whitespaces)
        let id = BoundPairID(parent: parent?.name, name: name)
        
        guard unique.subAccount(id: id, action: .insert) else { throw .init(value: id) }
        
        to.name = name
        to.parent = parent
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    public static func ==(lhs: SubAccountSnapshot, rhs: SubAccountSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
}
