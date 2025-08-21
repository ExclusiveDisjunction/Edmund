//
//  SubAccount.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/20/25.
//

import Foundation
import SwiftData

extension SubAccount : BoundPair, Equatable, UniqueElement, NamedElement, VoidableElement, TransactionHolder, CustomStringConvertible {
    public convenience init() {
        self.init("")
    }
    public convenience init(parent: Account?) {
        self.init("", parent: parent)
    }
    
    public static let objId: ObjectIdentifier = .init(SubAccount.self)
    
    public var id: BoundPairID {
        .init(parent: self.parentName, name: self.name)
    }
    
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
