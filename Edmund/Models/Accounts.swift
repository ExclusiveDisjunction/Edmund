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
        self.children = [];
    }
    init(_ name: String, creditLimit: Decimal? = nil, children: [SubAccount] = []) {
        self.name = name;
        self.creditLimit = creditLimit;
        self.children = children
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var id: String { name }
    @Attribute(.unique) var name: String;
    @Attribute var creditLimit: Decimal?;
    @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent) var children: [SubAccount];
    static var kind: NamedPairKind {
        .account
    }
    
    static let exampleAccounts: [Account] = {
        [
            exampleAccount,
            .init("Savings", creditLimit: nil, children: [
                .init("Main"),
                .init("Reserved"),
                .init("Rent")
            ]),
            .init("Credit", creditLimit: 3000, children: [
                .init("DI"),
                .init("Groceries")
            ])
        ]
    }()
    static let exampleAccount: Account = {
        .init("Checking", creditLimit: nil, children: [
            .init("DI"),
            .init("Gas"),
            .init("Health"),
            .init("Groceries"),
            .init("Pay"),
            .init("Credit Card")
        ])
    }()
}
@Model
final class SubAccount : BoundPair, Equatable {
    required init() {
        self.name = ""
        self.parent = Account();
        self.id = UUID();
        self.transactions = [];
    }
    init(_ name: String, parent: Account? = nil, id: UUID = UUID(), transactions: [LedgerEntry] = []) {
        self.name = name
        self.parent = parent
        self.id = id
        self.transactions = transactions
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
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account) var transactions: [LedgerEntry];
    
    static var kind: NamedPairKind {
        get { .account }
    }
    
    static var exampleSubAccount: SubAccount {
        .init("DI", parent: .init("Checking"))
    }
}
