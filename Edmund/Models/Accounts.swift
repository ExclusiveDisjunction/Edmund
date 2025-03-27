//
//  Accounts.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData

@Model
final class Account : Identifiable, Hashable, BoundPairParent {
    required init() {
        self.name = ""
        self.creditLimit = nil
        self.id = UUID()
    }
    init(_ name: String, creditLimit: Decimal? = nil) {
        self.name = name;
        self.creditLimit = creditLimit;
        self.id = UUID()
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var id: UUID;
    @Attribute(.unique) var name: String;
    @Attribute var creditLimit: Decimal?;
    @Relationship(deleteRule: .cascade) var children = [SubAccount]();
    
    var bound_pairs: [SubAccount] {
        get { children }
        set(v) { children = v }
    }
    static var kind: NamedPairKind {
        .account
    }
    
    var isEmpty : Bool {
        name.isEmpty
    }
    
    static var exampleAccounts: [Account] {
        let accounts: [Account] = ["Checking", "Savings", "Savor"].map({ Account($0) });
        accounts[0].creditLimit = 400;
        for account in accounts {
            account.children = ["DI", "Hold", "Bills"].map( { SubAccount($0, parent: account) })
        }
        
        return accounts;
    }
}
@Model
final class SubAccount : NamedPair, BoundPair {
    required init() {
        self.name = ""
        self.parent = Account();
        self.id = UUID();
    }
    init(_ name: String, parent: Account, id: UUID = UUID()) {
        self.name = name
        self.parent = parent
        self.id = id;
    }
    
    static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    
    @Attribute(.unique) var id: UUID;
    var name: String;
    @Relationship(deleteRule: .cascade, inverse: \Account.children) var parent: Account;
    
    var isEmpty: Bool {
        name.isEmpty || parent.name.isEmpty
    }
    
    var parent_name: String {
        get { parent.name }
        set(v) { parent.name = v }
    }
    var child_name: String {
        get { name }
        set(v) { name = v }
    }
    static var kind: NamedPairKind {
        get { .account }
    }
}
