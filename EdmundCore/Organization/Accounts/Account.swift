//
//  Accounts.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents the different kind of accounts for more dynamic choices on the UI.
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

/// Represents a location to store money, via the use of inner sub-accounts.
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
    /// The account's name. This must be unique. This can be simple like "Checking", or more elaborate like "Chase Savings"
    public var name: String = "";
    /// The credit limit stored within the system. It will only be provided and active if the account kind is `.credit`.
    private var rawCreditLimit: Decimal? = nil;
    /// The credit limit of the account. If the account is not a `.credit` kind, it will always return `nil`.
    /// Setting this value will not update the kind of account, and if it is not `.credit`, it will ignore the set.
    public var creditLimit: Decimal? {
        get {
            self.kind == .credit ? rawCreditLimit : nil
        }
        set {
            guard self.kind == .credit else { return }
            
            self.rawCreditLimit = newValue
        }
    }
    /// An optional interest value
    public var interest: Decimal? = nil;
    /// An optional description of where the account is physically
    public var location: String? = nil;
    /// The kind of account, used to make swift data happy.
    private var rawKind: Int = AccountKind.checking.rawValue;
    /// The account kind
    public var kind: AccountKind {
        get {
            .init(rawValue: rawKind)!
        }
        set {
            self.rawKind = newValue.rawValue
        }
    }
    /// The children for this account. Money is not held in the account itself, it is held in the sub accounts.
    @Relationship(deleteRule: .cascade, inverse: \SubAccount.parent)
    public var children: [SubAccount]
    
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
    public func removeFromEngine(unique: UniqueEngine) -> Bool {
        unique.account(id: self.id, action: .remove)
    }
    
    /// A list of template data to use on the UI.
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
    /// A singular account to display on the UI.
    public static let exampleAccount: Account = {
        .init("Checking", kind: .checking, creditLimit: nil, interest: 0.001, children: [
            .init("DI"),
            .init("Gas"),
            .init("Health"),
            .init("Groceries"),
            .init("Pay"),
            .init("Credit Card"),
            .init("Personal"),
            .init("Taxes"),
            .init("Bills")
        ])
    }()
    /// A singular account that is setup like a credit card.
    public static let exampleCreditAccount: Account = .init("Credit", kind: .credit, creditLimit: 3000, children: [ .init("DI"), .init("Gas") ] );
}

/// The snapshot type for `Account`.
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
        self.oldName = from.name;
    }

    private let oldName: String;
    
    /// The account's name
    public var name: String;
    /// True if the kind is `.credit`.
    public var hasCreditLimit: Bool {
        self.kind == .credit
    }
    /// The current credit limit.
    public var creditLimit: CurrencyValue;
    /// If the account has interest or not
    public var hasInterest: Bool;
    /// The interest value
    public var interest: Decimal;
    /// If the account has a location value
    public var hasLocation: Bool;
    /// The location
    public var location: String;
    /// The account's kind
    public var kind: AccountKind;
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result: [ValidationFailure] = [];
        
        let name = self.name.trimmingCharacters(in: .whitespaces);
        if name.isEmpty { result.append(.empty("Name")) }
        else if name != oldName && !unique.account(id: name, action: .validate) { result.append(.unique(Account.identifiers)) }
        
        if hasCreditLimit && creditLimit.rawValue < 0 { result.append(.negativeAmount("Credit Limit")) }
        if hasInterest {
            if interest < 0 { result.append(.negativeAmount("Interest")) }
            else if interest > 1 { result.append(.tooLargeAmount("Interest")) }
        }
        
        if hasLocation && location.trimmingCharacters(in: .whitespaces).isEmpty { result.append(.empty("Location")) }
        
        return result
    }
    public func apply(_ to: Account, context: ModelContext, unique: UniqueEngine) throws(UniqueFailueError<Account.ID>) {
        let name = self.name.trimmingCharacters(in: .whitespaces)
        
        if name != to.name {
            let _ = unique.account(id: to.name, action: .remove);
            guard unique.account(id: name, action: .insert) else { throw UniqueFailueError(value: name) }
        }
        
        to.name = name
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
