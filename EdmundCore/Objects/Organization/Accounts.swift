//
//  Accounts.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

public enum AccountKind : Int, Identifiable, Hashable, Codable, CaseIterable {
    case credit, checking, savings, cd, trust, cash
    
    public var id: Self { self }
    public var display: LocalizedStringKey {
        switch self {
            case .credit: "Credit"
            case .checking: "Checking"
            case .savings: "Savings"
            case .cd: "Certificate of Deposit"
            case .trust: "Trust Fund"
            case .cash: "Cash"
        }
    }
}

@Model
public final class Account : Identifiable, Hashable, BoundPairParent, NamedEditableElement, NamedInspectableElement, UniqueElement {
    public typealias EditView = AccountEdit;
    public typealias Snapshot = AccountSnapshot;
    public typealias InspectorView = AccountInspect;
    
    public convenience init() {
        self.init("")
    }
    public init(_ name: String, kind: AccountKind = .checking, creditLimit: Decimal? = nil, interest: Decimal? = nil, location: String? = nil, children: [SubAccount] = []) {
        self.name = name;
        self.rawKind = kind.rawValue;
        self.location = location
        self.interest = interest
        self.rawCreditLimit = creditLimit;
        self.children = children
    }
    
    public var id: String { name }
    public var name: String = "";
    private var rawCreditLimit: Decimal? = nil;
    public var creditLimit: Decimal? {
        get {
            self.kind == .credit ? rawCreditLimit : nil
        }
        set {
            guard self.kind == .credit else { return }
            
            self.rawCreditLimit = newValue
        }
    }
    public var interest: Decimal? = nil;
    public var location: String? = nil;
    private var rawKind: Int = AccountKind.checking.rawValue;
    public var kind: AccountKind {
        get {
            .init(rawValue: rawKind)!
        }
        set {
            self.rawKind = newValue.rawValue
        }
    }
    @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent) public var children: [SubAccount]? = nil;
    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Account",
            plural:   "Accounts",
            inspect:  "Inspect Account",
            edit:     "Edit Account",
            add:      "Add Account"
        )
    }
    public static var identifiers: [ElementIdentifer] {
        [ .init(name: "Name") ]
    }
    
    public static let exampleAccounts: [Account] = {
        [
            exampleAccount,
            .init("Savings", kind: .savings, creditLimit: nil, interest: 0.0425, location: "Chase", children: [
                .init("Main"),
                .init("Reserved"),
                .init("Rent")
            ]),
            .init("Credit", kind: .credit, creditLimit: 3000, interest: 0.1499, location: "Capital One", children: [
                .init("DI"),
                .init("Groceries")
            ]),
            .init("Visa", kind: .credit, creditLimit: 4000, interest: 0.2999, location: "Truist", children: [
                .init("DI"),
                .init("Groceries")
            ])
        ]
    }()
    public static let exampleAccount: Account = {
        .init("Checking", kind: .checking, creditLimit: nil, interest: 0.001, children: [
            .init("DI"),
            .init("Gas"),
            .init("Health"),
            .init("Groceries"),
            .init("Pay"),
            .init("Credit Card")
        ])
    }()
    public static let exampleCreditAccount: Account = .init("Credit", creditLimit: 3000, children: [ .init("DI"), .init("Gas") ] );
}
@Model
public final class SubAccount : BoundPair, Equatable, NamedEditableElement, NamedInspectableElement, UniqueElement, TransactionHolder {
    public typealias EditView = NamedPairChildEdit<SubAccount>
    public typealias Snapshot = NamedPairChildSnapshot<SubAccount>;
    public typealias InspectorView = SimpleElementInspect<SubAccount>;
    
    public convenience init() {
        self.init("")
    }
    public convenience init(parent: Account?) {
        self.init("", parent: parent)
    }
    public init(_ name: String, parent: Account? = nil, transactions: [LedgerEntry] = []) {
        self.name = name
        self.parent = parent
        self.transactions = transactions
    }
    
    public static func ==(lhs: SubAccount, rhs: SubAccount) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    
    public var id: String {
        "\(self.parent_name ?? "").\(self.name)"
    }
    public var name: String = "";
    @Relationship public var parent: Account? = nil;
    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.account) public var transactions: [LedgerEntry]? = nil;
    
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
    
    public static var exampleSubAccount: SubAccount {
        .init("DI", parent: .init("Checking"))
    }
}


@Observable
public final class AccountSnapshot : ElementSnapshot {
    public typealias Host = Account
    
    public init(_ from: Account) {
        self.name = from.name;
        self.creditLimit = CurrencyValue(rawValue: from.creditLimit ?? Decimal());
        self.hasInterest = from.interest != nil;
        self.interest = from.interest ?? .init();
        self.hasLocation = from.location != nil;
        self.location = from.location ?? String();
        self.kind = from.kind;
    }
    
    public var name: String;
    public var hasCreditLimit: Bool {
        self.kind == .credit
    }
    public var creditLimit: CurrencyValue;
    public var hasInterest: Bool;
    public var interest: Decimal;
    public var hasLocation: Bool;
    public var location: String;
    public var kind: AccountKind;
    
    public func validate() -> Bool {
        guard !self.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false;
        }
        
        if hasCreditLimit && creditLimit.rawValue < 0 {
            return false;
        }
        
        if hasInterest && interest < 0 {
            return false;
        }
        
        if hasLocation && location.trimmingCharacters(in: .whitespaces).isEmpty {
            return false;
        }
        
        return true;
    }
    public func apply(_ to: Account, context: ModelContext) {
        to.name = self.name.trimmingCharacters(in: .whitespaces)
        to.creditLimit = self.hasCreditLimit ? self.creditLimit.rawValue : nil;
        to.interest = self.hasInterest ? self.interest : nil;
        to.location = self.hasLocation ? self.location : nil;
        to.kind = self.kind
    }
    
    public static func == (lhs: AccountSnapshot, rhs: AccountSnapshot) -> Bool {
        guard lhs.name == rhs.name && lhs.kind == rhs.kind && lhs.hasInterest == rhs.hasInterest && lhs.hasLocation == rhs.hasLocation else {
            return false;
        }
        
        // Since hasInterest, hasLocation, and hasCreditLimit have been checked, lhs can determine if those values need to be compared.
        if lhs.hasInterest && lhs.interest != rhs.interest {
            return false;
        }
        
        if lhs.hasLocation && lhs.location != rhs.location {
            return false;
        }
        
        if lhs.hasCreditLimit && lhs.creditLimit != rhs.creditLimit {
            return false;
        }
        
        return true;
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.creditLimit)
        hasher.combine(self.hasInterest)
        hasher.combine(self.interest)
        hasher.combine(self.hasLocation)
        hasher.combine(self.location)
        hasher.combine(self.kind)
    }
}
