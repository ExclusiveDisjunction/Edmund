//
//  SubAccount.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/20/25.
//

import Foundation
import SwiftData

extension EdmundModelsV1 {
    /// Represents a sub-section under an account for transaction grouping.
    @Model
    public final class SubAccount : BoundPair, Equatable, SnapshotableElement, UniqueElement, NamedElement, VoidableElement, TransactionHolder, CustomStringConvertible {
        public typealias Snapshot = SubAccountSnapshot;
        
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
        
        public static let objId: ObjectIdentifier = .init(SubAccount.self)
        
        public var id: BoundPairID {
            .init(parent: self.parentName, name: self.name)
        }
        public var name: String = "";
        public private(set) var isVoided: Bool = false
        @Relationship
        public var parent: Account? = nil;
        @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account)
        public var transactions: [LedgerEntry]? = nil;
        
        @Relationship(deleteRule: .nullify, inverse: \IncomeDivision.depositTo)
        public var budgetInstances: [IncomeDivision] = [];
        @Relationship(deleteRule: .nullify, inverse: \AmountDevotion.account)
        public var amountDevotions: [AmountDevotion] = [];
        @Relationship(deleteRule: .nullify, inverse: \PercentDevotion.account)
        public var percentDevotions: [PercentDevotion] = [];
        @Relationship(deleteRule: .nullify, inverse: \RemainderDevotion.account)
        public var remainderDevotions: [RemainderDevotion] = [];
        
        public func setVoidStatus(_ new: Bool) {
            guard new != isVoided else {
                return;
            }
            
            if new {
                self.isVoided = true;
                transactions?.forEach { $0.setVoidStatus(true) }
            }
            else {
                self.isVoided = false;
            }
        }
        
        public var description: String {
            "Sub Account \(id)"
        }
        
        public func makeSnapshot() -> SubAccountSnapshot {
            .init(self)
        }
        public static func makeBlankSnapshot() -> SubAccountSnapshot {
            .init()
        }
        public func update(_ from: SubAccountSnapshot, unique: UniqueEngine) async throws (UniqueFailureError<BoundPairID>) {
            let name = from.name.trimmingCharacters(in: .whitespaces)
            let id = BoundPairID(parent: parent?.name, name: name)
            
            if self.id != id {
                let result = await unique.swapId(key: .init(SubAccount.self), oldId: self.id, newId: id)
                guard result else {
                    throw UniqueFailureError(value: id)
                }
            }
            
            self.name = name
            self.parent = parent
        }
        
        @MainActor
        public func tryNewName(name: String, unique: UniqueEngine) async -> Bool {
            let newId = BoundPairID(parent: self.parentName, name: name)
            
            guard newId != self.id else { return true; }
            
            return await unique.isIdOpen(key: .init(SubAccount.self), id: newId)
        }
        @MainActor
        public func takeNewName(name: String, unique: UniqueEngine) async throws(UniqueFailureError<BoundPairID>) {
            guard name != self.name else {
                return;
            }
            
            let newId = BoundPairID(parent: self.parentName, name: name)
            let result = await unique.swapId(key: Self.objId, oldId: self.id, newId: newId)
            guard result else {
                throw .init(value: newId)
            }
            
            self.name = name;
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
}

public typealias SubAccount = EdmundModelsV1.SubAccount

/// The snapshot type for `SubAccount`.
@Observable
public final class SubAccountSnapshot: ElementSnapshot {
    public init() {
        self.name = "";
        self.parent = nil;
        self.oldId = .init(parent: nil, name: "")
    }
    public init(_ from: SubAccount) {
        self.name = from.name;
        self.parent = from.parent
        self.oldId = from.id;
    }
    
    @ObservationIgnored private let oldId: BoundPairID;
    
    /// The sub-account's name
    public var name: String;
    /// The sub-account's parent account
    public var parent: Account?;
    
    public func validate(unique: UniqueEngine) async -> ValidationFailure? {
        let name = name.trimmingCharacters(in: .whitespaces);
        let id = BoundPairID(parent: parent?.name, name: name)
        
        if oldId != id {
            guard await unique.isIdOpen(key: .init(SubAccount.self), id: id) else {
                return .unique
            }
        }
        
        guard !name.isEmpty && parent != nil else { return .empty }
        
        return nil;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    public static func ==(lhs: SubAccountSnapshot, rhs: SubAccountSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
}
