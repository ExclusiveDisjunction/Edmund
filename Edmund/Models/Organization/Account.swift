//
//  Account.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI

/// Represents the different kind of accounts for more dynamic choices on the UI.
public enum AccountKind : Int16, Identifiable, Hashable, Codable, CaseIterable {
    case credit, checking, savings, cd, trust, cash
    
    public var id: Self { self }
}
extension AccountKind : Displayable {
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

extension Account : DefaultableElement, VoidableElement {
    public var name: String {
        get { self.internalName ?? "" }
        set { self.internalName = newValue }
    }
    
    /// The credit limit of the account. If the account is not a `.credit` kind, it will always return `nil`.
    /// Setting this value will not update the kind of account, and if it is not `.credit`, it will ignore the set.
    public var creditLimit: Decimal? {
        get {
            self.kind == .credit ? self.internalCreditLimit as Decimal? : nil
        }
        set {
            guard self.kind == .credit else { return }
            
            self.internalCreditLimit = newValue as NSDecimalNumber?
        }
    }
    /// The account kind
    public var kind: AccountKind {
        get {
            AccountKind(rawValue: self.internalKind) ?? .checking
        }
        set {
            self.internalKind = newValue.rawValue
        }
    }
    
    public func setVoidStatus(_ new: Bool) {
        guard new != isVoided else {
            return
        }
        
        if new {
            self.isVoided = true
        
            if let rawEnvolopes = self.envolope, let envolopes = rawEnvolopes as? Set<Envolope> {
                envolopes.forEach { $0.setVoidStatus(true) }
            }
        }
        else {
            self.isVoided = false;
        }
    }
    
    /*
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
    */
     
    public static func exampleAccounts(cx: NSManagedObjectContext) {
        let savings = Account(context: cx);
        savings.internalName = "Savings";
        savings.kind = .savings;
        savings.creditLimit = nil;
        savings.interest = 0.0425
        savings.location = "Chase";
        
        let checing = Account(context: cx);
        checing.internalName = "Checking";
        checing.kind = .checking;
        checing.creditLimit = nil;
        checing.interest = 0.001
        checing.location = "Capital One";
        
        let credit = Account(context: cx);
        credit.internalName = "Credit";
        credit.kind = .credit;
        credit.creditLimit = 3000;
        credit.interest = 0.2999;
        credit.location = "Capital One";
    }
}

/*
 extension Account: EditableElement, InspectableElement, TypeTitled {
 public static var typeDisplay : TypeTitleStrings {
 .init(
 singular: "Account",
 plural:   "Accounts",
 inspect:  "Inspect Account",
 edit:     "Edit Account",
 add:      "Add Account"
 )
 }
 
 public func makeInspectView() -> AccountInspect {
 AccountInspect(self)
 }
 public static func makeEditView(_ snap: Snapshot) -> AccountEdit {
 AccountEdit(snap)
 }
 }
 */
