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
    public typealias EditView = SimpleElementEdit<Account>
    public typealias Snapshot = SimpleElementSnapshot<Account>
    public typealias InspectorView = SimpleElementInspect<Account>
    
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
    public var name: String = "";
    public var creditLimit: Decimal? = nil;
    @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent) public var children: [SubAccount]? = nil;
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
public final class SubAccount : BoundPair, Equatable, EditableElement, InspectableElement, TransactionHolder {
    public typealias EditView = NamedPairChildEdit<SubAccount>
    public typealias Snapshot = NamedPairChildSnapshot<SubAccount>;
    public typealias InspectorView = SimpleElementInspect<SubAccount>;
    
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
    
    public var id: UUID = UUID();
    public var name: String = "";
    @Relationship public var parent: Account? = nil;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account) public var transactions: [LedgerEntry]? = nil;
    
    public static var kind: NamedPairKind {
        get { .account }
    }
    
    public static var exampleSubAccount: SubAccount {
        .init("DI", parent: .init("Checking"))
    }
}
