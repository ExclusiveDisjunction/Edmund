//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import SwiftUI;
import Foundation;

/// The displayed value of the ledger style
public enum LedgerStyle: Int, Identifiable, CaseIterable {
    /// Display credits as 'money in', and debits as 'money out'
    case none = 0
    /// Display credits as 'debit', and debits as 'credit'
    case standard = 1
    /// Display credits as 'credit', and debits as 'debit'
    case reversed = 2
    
    /// A UI ready description of what the value is
    public var description: LocalizedStringKey {
        switch self {
            case .none: "Do not show as Accounting Style"
            case .standard: "Standard Accounting Style"
            case .reversed: "Reversed Accounting Style"
        }
    }
    /// The value to use for a 'credit' field.
    public var displayCredit: LocalizedStringKey {
        switch self {
            case .none: "Money In"
            case .standard: "Debit"
            case .reversed: "Credit"
        }
    }
    /// The value to use for a 'debit' field.
    public var displayDebit: LocalizedStringKey {
        switch self {
            case .none: "Money Out"
            case .standard: "Credit"
            case .reversed: "Debit"
        }
    }
    public var id: Self { self }
}

/// A record into the ledger, representing a single transaction.
@Model
public final class LedgerEntry : Identifiable, NamedInspectableElement, NamedEditableElement {
    public typealias InspectorView = LedgerEntryInspect;
    public typealias EditView = LedgerEntryEdit;
    public typealias Snapshot = LedgerEntrySnapshot;
    
    /// Creates an empty transaction
    public init() {
        self.id = UUID()
        self.name = ""
        self.credit = 0
        self.debit = 0
        self.date = Date.now
        self.addedOn = Date.now;
        self.location = ""
        self.category = nil
        self.account = nil
    }
    /// Creates a transactions with specified values.
    public init(name: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: SubCategory, account: SubAccount) {
        self.id = UUID()
        self.name = name
        self.credit = credit
        self.debit = debit
        self.date = date
        self.addedOn = added_on;
        self.location = location
        self.category = category
        self.account = account
    }
    
    public var id: UUID = UUID()
    /// The memo of the transaction, a simple overview of the transaction
    public var name: String = "";
    /// How much money came in
    public var credit: Decimal = 0;
    /// How much money left
    public var debit: Decimal = 0;
    /// When it occured
    public var date: Date = Date.now;
    /// When it was recorded
    public var addedOn: Date = Date.now;
    /// The lcoation where it happened.
    public var location: String = "";
    /// The associated parent sub category
    @Relationship
    public var category: SubCategory? = nil;
    /// The associated parent sub account
    @Relationship
    public var account: SubAccount? = nil;
    
    /// The net difference between credit and debit
    public var balance: Decimal {
        credit - debit
    }
    
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Transaction",
            plural:   "Transactions",
            inspect:  "Inspect Transaction",
            edit:     "Edit Transaction",
            add:      "Add Transaction"
        )
    }
    
    /// Builds a list of ledger entries over some accounts and categories. It expects specific ones to exist, and may cause a crash if they dont.
    /// This is intended for internal use.
    public static func exampleEntries(acc: [Account], cat: [Category]) -> [LedgerEntry] {
        let transferCat = cat.findPair("Account Control", "Transfer")!
        let auditCat = cat.findPair("Account Control", "Audit")!
        let initialCat = cat.findPair("Account Control", "Initial")!
        let diCat = cat.findPair("Personal", "Dining")!
        let groceriesCat = cat.findPair("Home", "Groceries")!
        let gasCat = cat.findPair("Car", "Gas")!
        
        let payAcc = acc.findPair("Checking", "Pay")!
        let diAcc = acc.findPair("Checking", "DI")!
        let creditCardAcc = acc.findPair("Checking", "Credit Card")!
        let gasAcc = acc.findPair("Checking", "Gas")!
        let groceriesAcc = acc.findPair("Checking", "Groceries")!
        let savingsMain = acc.findPair("Savings", "Main")!
        let creditDI = acc.findPair("Credit", "DI")!
        let creditGroceries = acc.findPair("Credit", "Groceries")!
        
        return [
            .init(name: "Initial Balance", credit: 1000, debit: 0, date: Date.now, location: "Bank", category: initialCat, account: savingsMain),
            .init(name: "Initial Balance", credit: 170, debit: 0, date: Date.now, location: "Bank", category: initialCat, account: payAcc),
            .init(name: "'Pay' to Various", credit: 0, debit: 100, date: Date.now, location: "Bank", category: transferCat, account: payAcc),
            .init(name: "'Pay' to 'DI'", credit: 35, debit: 0, date: Date.now, location: "Bank", category: transferCat, account: diAcc),
            .init(name: "'Pay' to 'Groceries'", credit: 65, debit: 0, date: Date.now, location: "Bank", category: transferCat, account: groceriesAcc),
            .init(name: "Lunch", credit: 0, debit: 20, date: Date.now, location: "Chick-Fil-A", category: diCat, account: creditDI),
            .init(name: "Groceries", credit: 0, debit: 40, date: Date.now, location: "Aldi", category: groceriesCat, account: creditGroceries),
            .init(name: "'Groceries' to 'Credit Card'", credit: 0, debit: 40, date: Date.now, location: "Bank", category: transferCat, account: groceriesAcc),
            .init(name: "'DI' to 'Credit Card'", credit: 0, debit: 20, date: Date.now, location: "Bank", category: transferCat, account: diAcc),
            .init(name: "Various to 'Credit Card'", credit: 60, debit: 0, date: Date.now, location: "Bank", category: transferCat, account: creditCardAcc),
            .init(name: "Gas", credit: 0, debit: 45, date: Date.now, location: "7-Eleven", category: gasCat, account: gasAcc),
            .init(name: "Audit", credit: 0, debit: 10, date: Date.now, location: "Bank", category: auditCat, account: payAcc)
        ]
    }
    
    /// A UI-ready filler example of a ledger entry
    public static let exampleEntry = LedgerEntry(name: "Example Transaction", credit: 0, debit: 100, date: Date.now, location: "Bank", category: .init("Example Sub Category", parent: .init("Example Category")), account: .init("Example Sub Account", parent: .init("Example Account")));
}

/// The snapshot for `LedgerEntry`
@Observable
public final class LedgerEntrySnapshot : ElementSnapshot {
    public typealias Host = LedgerEntry;
    
    /// Creates a blank snapshot with default values.
    public init() {
        name = .init();
        credit = 0;
        debit = 0;
        date = .now;
        location = "";
        category = nil;
        account = nil;
    }
    public init(_ from: LedgerEntry) {
        name     = from.name;
        credit   = from.credit;
        debit    = from.debit;
        date     = from.date;
        location = from.location;
        category = from.category;
        account  = from.account;
    }
    
    /// The memo of the transaction
    public var name: String = "";
    /// The money in
    public var credit: Decimal = 0;
    /// The money leaving
    public var debit: Decimal = 0;
    /// The date in which the transaction occured
    public var date: Date = Date.now;
    /// The location in which it occured
    public var location: String = "";
    /// The associated category
    public var category: SubCategory? = nil;
    /// The associated sub account
    public var account: SubAccount? = nil;
    
    /// The net between credit and debit
    public var balance: Decimal {
        credit - debit
    }
    
    public func validate(unique: UniqueEngine) -> [ValidationFailure] {
        var result: [ValidationFailure] = [];
        
        if category == nil { result.append(.empty("Category")) }
        if account == nil { result.append(.empty("Account")) }
    
        return result
    }
    public func apply(_ to: LedgerEntry, context: ModelContext, unique: UniqueEngine) {
        to.name     = name;
        to.credit   = credit;
        to.debit    = debit;
        to.date     = date;
        to.location = location;
        to.category = category;
        to.account  = account;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name);
        hasher.combine(credit);
        hasher.combine(debit);
        hasher.combine(date);
        hasher.combine(location);
        hasher.combine(category);
        hasher.combine(account);
    }
    
    public static func == (lhs: LedgerEntrySnapshot, rhs: LedgerEntrySnapshot) -> Bool {
        lhs.name == rhs.name  && lhs.credit == rhs.credit && lhs.debit == rhs.debit && lhs.date == rhs.date && lhs.location == rhs.location && lhs.category == rhs.category && lhs.account == rhs.account
    }
}
