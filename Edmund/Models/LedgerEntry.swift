//
//  LedgerEntry.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/1/25.
//

import SwiftUI

/*
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
 */

extension LedgerEntry : VoidableElement, NamedElement {
    
    public var name: String {
        get { self.internalMemo ?? "" }
        set { self.internalMemo = newValue }
    }
    public var location: String {
        get { self.internalLocation ?? "" }
        set { self.internalLocation = newValue }
    }
    public var date: Date {
        get { self.internalDate ?? .distantPast }
        set { self.internalDate = newValue }
    }
    public var addedOn: Date {
        get { self.internalAddedOn ?? .distantPast }
        set { self.internalAddedOn = newValue }
    }
    
    public var credit: Decimal {
        get { (self.internalCredit as Decimal?) ?? 0.0 }
        set { self.internalCredit = newValue as NSDecimalNumber }
    }
    public var debit: Decimal {
        get { (self.internalDebit as Decimal?) ?? 0.0 }
        set { self.internalCredit = newValue as NSDecimalNumber }
    }
    /// The net difference between credit and debit
    public var balance: Decimal {
        credit - debit
    }
    
    public func setVoidStatus(_ new: Bool) {
        self.isVoided = new;
    }
    
    /*
    public func update(_ from: LedgerEntrySnapshot, unique: UniqueEngine) {
        self.name = from.name.trimmingCharacters(in: .whitespaces)
        self.credit = from.credit.rawValue
        self.debit = from.debit.rawValue
        self.date = from.date
        self.location = from.location
        self.category = from.category
        self.account = from.account
    }
     */
    
    /// Builds a list of ledger entries over some accounts and categories. It expects specific ones to exist, and may cause a crash if they dont.
    /// This is intended for internal use.
    @MainActor
    public static func exampleEntries(acc: inout AccountLocator, cat: inout ElementLocator<Category>, cx: NSManagedObjectContext) {
        let transferCat = cat.getOrInsert(name: "Transfers", cx: cx);
        let auditCat = cat.getOrInsert(name: "Adjustments", cx: cx);
        let personalCat = cat.getOrInsert(name: "Personal", cx: cx);
        let groceriesCat = cat.getOrInsert(name: "Groceries", cx: cx);
        let carCat = cat.getOrInsert(name: "Car", cx: cx);
        
        let pay = acc.getOrInsertEnvolope(name: "Pay", accountName: "Checking", cx: cx);
        let di = acc.getOrInsertEnvolope(name: "DI", accountName: "Checking", cx: cx);
        let groceries = acc.getOrInsertEnvolope(name: "Groceries", accountName: "Checking", cx: cx);
        let diCredit = acc.getOrInsertEnvolope(name: "DI", accountName: "Credit", cx: cx);
        let gas = acc.getOrInsertEnvolope(name: "Gas", accountName: "Checking", cx: cx);
        let savings = acc.getOrInsertEnvolope(name: "Main", accountName: "Savings", cx: cx)
        
        
        // memo, credit, debit, location, category, account
        let toTransform: [(String, Decimal, Decimal, String, Category, Envolope)] = [
            ("Initial Balance",              1000, 0,   "Bank",        auditCat,     savings    ),
            ("Initial Balance",              170,  0,   "Bank",        auditCat,     pay        ),
            ("'Pay' to Various",             0,    100, "Bank",        transferCat,  pay        ),
            ("'Pay' to 'DI'",                35,   0,   "Bank",        transferCat,  di         ),
            ("'Pay' to 'Groceries'",         65,   0,   "Bank",        transferCat,  groceries  ),
            ("Lunch",                        0,    20,  "Chick-Fil-A", personalCat,  diCredit   ),
            ("Groceries",                    0,    40,  "Aldi",        groceriesCat, groceries  ),
            ("'Groceries' to 'Credit Card'", 0,    40,  "Bank",        transferCat,  groceries  ),
            ("'DI' to 'Credit Card'",        0,    20,  "Bank",        transferCat,  di         ),
            ("Various to 'Credit Card'",     60,   0,   "Bank",        transferCat,  diCredit   ),
            ("Gas",                          0,    45,  "7-Eleven",    carCat,       gas        ),
            ("Audit",                        0,    10,  "Bank",        auditCat,     pay        )
        ];
        
        for (memo, credit, debit, location, cat, acc) in toTransform {
            let entry = LedgerEntry(context: cx);
            entry.name = memo;
            entry.credit = credit;
            entry.debit = debit;
            entry.location = location
            entry.category = cat
            entry.envolope = acc;
        }
    }
}

/*
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
*/
