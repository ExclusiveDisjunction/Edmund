//
//  LedgerEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI

extension LedgerEntry : EditableElement, InspectableElement, TypeTitled {
    public static var typeDisplay : TypeTitleStrings {
        .init(
            singular: "Transaction",
            plural:   "Transactions",
            inspect:  "Inspect Transaction",
            edit:     "Edit Transaction",
            add:      "Add Transaction"
        )
    }
    
    public func makeInspectView() -> LedgerEntryInspect {
        LedgerEntryInspect(self)
    }
    public static func makeEditView(_ snap: LedgerEntrySnapshot) -> LedgerEntryEdit {
        LedgerEntryEdit(snap)
    }
}

extension LedgerEntry : SnapshotableElement, VoidableElement, NamedElement, DefaultableElement {
    public typealias Snapshot = LedgerEntrySnapshot;
    
    /// Creates an empty transaction
    public convenience init() {
        self.init(
            name: "",
            credit: 0,
            debit: 0,
            date: .now,
            location: "",
            category: nil,
            account: nil
        )
    }
    
    /// The net difference between credit and debit
    public var balance: Decimal {
        credit - debit
    }
    
    public func setVoidStatus(_ new: Bool) {
        self.isVoided = new;
    }
    
    public func makeSnapshot() -> LedgerEntrySnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> LedgerEntrySnapshot {
        .init()
    }
    public func update(_ from: LedgerEntrySnapshot, unique: UniqueEngine) {
        self.name = from.name.trimmingCharacters(in: .whitespaces)
        self.credit = from.credit.rawValue
        self.debit = from.debit.rawValue
        self.date = from.date
        self.location = from.location
        self.category = from.category
        self.account = from.account
    }
    
    /// Builds a list of ledger entries over some accounts and categories. It expects specific ones to exist, and may cause a crash if they dont.
    /// This is intended for internal use.
    @MainActor
    public static func exampleEntries(acc: inout ElementLocator<Account>, cat: inout ElementLocator<Category>) -> [LedgerEntry] {
        let transferCat = cat.getOrInsert(name: "Transfers");
        let auditCat = cat.getOrInsert(name: "Adjustments");
        let personalCat = cat.getOrInsert(name: "Personal");
        let groceriesCat = cat.getOrInsert(name: "Groceries");
        let carCat = cat.getOrInsert(name: "Car");
        
        let checking = acc.getOrInsert(name: "Checking")
        let savings = acc.getOrInsert(name: "Savings")
        let credit = acc.getOrInsert(name: "Credit")
        
        return [
            .init(name: "Initial Balance",              credit: 1000, debit: 0,   date: Date.now, location: "Bank",        category: auditCat,    account: savings  ),
            .init(name: "Initial Balance",              credit: 170,  debit: 0,   date: Date.now, location: "Bank",        category: auditCat,    account: checking ),
            .init(name: "'Pay' to Various",             credit: 0,    debit: 100, date: Date.now, location: "Bank",        category: transferCat, account: checking ),
            .init(name: "'Pay' to 'DI'",                credit: 35,   debit: 0,   date: Date.now, location: "Bank",        category: transferCat, account: checking ),
            .init(name: "'Pay' to 'Groceries'",         credit: 65,   debit: 0,   date: Date.now, location: "Bank",        category: transferCat, account: checking ),
            .init(name: "Lunch",                        credit: 0,    debit: 20,  date: Date.now, location: "Chick-Fil-A", category: personalCat, account: credit   ),
            .init(name: "Groceries",                    credit: 0,    debit: 40,  date: Date.now, location: "Aldi",        category: groceriesCat,account: credit   ),
            .init(name: "'Groceries' to 'Credit Card'", credit: 0,    debit: 40,  date: Date.now, location: "Bank",        category: transferCat, account: checking ),
            .init(name: "'DI' to 'Credit Card'",        credit: 0,    debit: 20,  date: Date.now, location: "Bank",        category: transferCat, account: checking ),
            .init(name: "Various to 'Credit Card'",     credit: 60,   debit: 0,   date: Date.now, location: "Bank",        category: transferCat, account: credit   ),
            .init(name: "Gas",                          credit: 0,    debit: 45,  date: Date.now, location: "7-Eleven",    category: carCat,      account: checking ),
            .init(name: "Audit",                        credit: 0,    debit: 10,  date: Date.now, location: "Bank",        category: auditCat,    account: checking )
        ]
    }
    
    /// A UI-ready filler example of a ledger entry
    @MainActor
    public static let exampleEntry = LedgerEntry(name: "Example Transaction", credit: 0, debit: 100, date: Date.now, location: "Bank", category: .init("Example Category"), account: .init("Example Account"));
}

/// The snapshot for `LedgerEntry`
@Observable
public final class LedgerEntrySnapshot : ElementSnapshot {
    /// Creates a blank snapshot with default values.
    public init() {
        name = .init();
        credit = .init();
        debit = .init()
        date = .now;
        location = "";
        category = nil;
        account = nil;
    }
    public init(_ from: LedgerEntry) {
        name     = from.name;
        credit   = .init(rawValue: from.credit);
        debit    = .init(rawValue: from.debit);
        date     = from.date;
        location = from.location;
        category = from.category;
        account  = from.account;
    }
    
    /// The memo of the transaction
    public var name: String;
    /// The money in
    public var credit: CurrencyValue
    /// The money leaving
    public var debit: CurrencyValue
    /// The date in which the transaction occured
    public var date: Date;
    /// The location in which it occured
    public var location: String
    /// The associated category
    public var category: Category?
    /// The associated sub account
    public var account: Account?
    
    /// The net between credit and debit
    public var balance: Decimal {
        credit.rawValue - debit.rawValue
    }
    
    public func validate(unique: UniqueEngine) -> ValidationFailure? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty || category == nil || account == nil { return .empty }
        
        return nil
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
