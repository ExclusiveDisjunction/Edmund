//
//  Accounts.swift
//  Edmund
//
//  Created by Hollan on 1/15/25.
//

import Foundation
import SwiftData

/// Represents the different kind of accounts for more dynamic choices on the UI.
public enum AccountKind : Int, Identifiable, Hashable, Codable, CaseIterable, Sendable {
    case credit, checking, savings, cd, trust, cash
    
    public var id: Self { self }
}

extension Account : Hashable, SnapshotableElement, DefaultableElement, SnapshotConstructableElement, UniqueElement, NamedElement, VoidableElement, TransactionHolder, CustomStringConvertible {
    public typealias Snapshot = AccountSnapshot;
    
    public convenience init() {
        self.init("")
    }
    public convenience init(snapshot: AccountSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        self.init();
        try await self.update(snapshot, unique: unique)
    }
    
    public static let objId: ObjectIdentifier = .init(Account.self)
    
    public var uID: String { name }
    /// The credit limit of the account. If the account is not a `.credit` kind, it will always return `nil`.
    /// Setting this value will not update the kind of account, and if it is not `.credit`, it will ignore the set.
    public var creditLimit: Decimal? {
        get {
            self.kind == .credit ? _creditLimit : nil
        }
        set {
            guard self.kind == .credit else { return }
            
            self._creditLimit = newValue
        }
    }
    /// The account kind
    public var kind: AccountKind {
        get {
            .init(rawValue: _kind) ?? .checking
        }
        set {
            self._kind = newValue.rawValue
        }
    }
    
    public func setVoidStatus(_ new: Bool) {
        guard new != isVoided else {
            return
        }
        
        if new {
            self.isVoided = true
            transactions.forEach { $0.setVoidStatus(true) }
        }
        else {
            self.isVoided = false;
        }
    }
    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public var description: String {
        "Account \(name)"
    }
    
    public func makeSnapshot() -> AccountSnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> AccountSnapshot {
        .init()
    }
    public func update(_ from: AccountSnapshot, unique: UniqueEngine) async throws(UniqueFailureError) {
        let name = from.name.trimmingCharacters(in: .whitespaces)
        
        if name != self.name {
            let result = await unique.swapId(key: .init(Account.self), oldId: self.name, newId: name)
            guard result else {
                throw UniqueFailureError(value: name)
            }
        }
        
        self.name = name
        self.kind = from.kind
        self._creditLimit = from.hasCreditLimit ? from.creditLimit.rawValue : nil;
        self.interest = from.hasInterest ? from.interest.rawValue : nil;
        self.location = from.hasLocation ? from.location : nil;
    }
    
    /// A list of template data to use on the UI.
    @MainActor
    public static var exampleAccounts: [Account] {
        [
            exampleAccount,
            .init("Savings", kind: .savings, creditLimit: nil, interest: 0.0425, location: "Chase"),
            .init("Credit", kind: .credit, creditLimit: 3000, interest: 0.1499, location: "Capital One"),
            .init("Visa", kind: .credit, creditLimit: 4000, interest: 0.2999, location: "Truist")
        ]
    }
    /// A singular account to display on the UI.
    @MainActor
    public static var exampleAccount: Account {
        .init("Checking", kind: .checking, creditLimit: nil, interest: 0.001)
    }
    
    /// A singular account that is setup like a credit card.
    @MainActor
    public static var exampleCreditAccount: Account {
        .init("Credit", kind: .credit, creditLimit: 3000)
    }
}

/// The snapshot type for `Account`.
@Observable
public final class AccountSnapshot : ElementSnapshot {
    public init() {
        self.oldName = ""
        self.name = ""
        self.creditLimit = .init()
        self.hasInterest = false
        self.interest = .init()
        self.hasLocation = false
        self.location = ""
        self.kind = .checking
    }
    public init(_ from: Account) {
        self.name = from.name;
        self.creditLimit = CurrencyValue(rawValue: from.creditLimit ?? Decimal());
        self.hasInterest = from.interest != nil;
        self.interest = .init(rawValue: from.interest ?? 0)
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
    public var interest: PercentValue;
    /// If the account has a location value
    public var hasLocation: Bool;
    /// The location
    public var location: String;
    /// The account's kind
    public var kind: AccountKind;
    
    public func validate(unique: UniqueEngine) async -> ValidationFailure? {
        let name = self.name.trimmingCharacters(in: .whitespaces);
        guard !name.isEmpty else { return .empty }
        if oldName != name {
            guard await unique.isIdOpen(key: .init(Account.self), id: name) else {
                return .unique
            }
        }
        
        if hasCreditLimit && creditLimit < 0 { return .negativeAmount }
        if hasInterest {
            if interest < 0 { return .negativeAmount }
            else if interest > 1 { return .tooLargeAmount }
        }
        
        if hasLocation && location.trimmingCharacters(in: .whitespaces).isEmpty { return .empty }
        
        return nil
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
}
