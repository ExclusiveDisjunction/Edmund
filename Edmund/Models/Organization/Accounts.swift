//
//  Accounts.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData

@Model
public final class Account : Identifiable, Hashable, BoundPairParent, EditableElement, InspectableElement {
    typealias EditView = SimpleElementEdit<Account>
    typealias Snapshot = SimpleElementSnapshot<Account>
    typealias InspectorView = SimpleElementInspect<Account>
    
    
    public required init() {
        self.name = ""
        self.creditLimit = nil
        self.children = [];
    }
    public init(_ name: String, creditLimit: Decimal? = nil, children: [SubAccount] = []) {
        self.name = name;
        self.creditLimit = creditLimit;
        self.children = children
    }
    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public var id: String { name }
    @Attribute(.unique) public var name: String;
    @Attribute public var creditLimit: Decimal?;
    @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent) public var children: [SubAccount];
    public static var kind: NamedPairKind {
        .account
    }
    
    public static let exampleAccounts: [Account] = {
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
    public static let exampleAccount: Account = {
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
public final class SubAccount : BoundPair, Equatable, EditableElement, InspectableElement {
    
    typealias EditView = NamedPairChildEdit<SubAccount>
    typealias Snapshot = NamedPairChildSnapshot<SubAccount>;
    typealias InspectorView = SimpleElementInspect<SubAccount>;
    
    public required init() {
        self.name = ""
        self.parent = nil 
        self.id = UUID();
        self.transactions = [];
    }
    public required init(parent: Account?) {
        self.name = ""
        self.parent = parent
        self.id = UUID()
        self.transactions = []
    }
    public init(_ name: String, parent: Account? = nil, id: UUID = UUID(), transactions: [LedgerEntry] = []) {
        self.name = name
        self.parent = parent
        self.id = id
        self.transactions = transactions
    }
    
    public static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    
    @Attribute(.unique) public var id: UUID;
    public var name: String;
    @Relationship public var parent: Account?;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account) public var transactions: [LedgerEntry];
    
    public static var kind: NamedPairKind {
        get { .account }
    }
    
    public static var exampleSubAccount: SubAccount {
        .init("DI", parent: .init("Checking"))
    }
}
