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
    @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent) var children = [SubAccount]();
    static var kind: NamedPairKind {
        .account
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
final class SubAccount : BoundPair, Equatable {
    required init() {
        self.name = ""
        self.parent = Account();
        self.id = UUID();
    }
    init(_ name: String, parent: Account?, id: UUID = UUID()) {
        self.name = name
        self.parent = parent
        self.id = id
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
    @Relationship var parent: Account?;
    
    static var kind: NamedPairKind {
        get { .account }
    }
}
