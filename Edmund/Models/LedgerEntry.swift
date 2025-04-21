//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

@Observable
public final class LedgerEntrySnapshot : ElementSnapshot
{
    typealias Host = LedgerEntry;
    
    init(_ from: LedgerEntry) {
        name     = from.name;
        credit   = from.credit;
        debit    = from.debit;
        date     = from.date;
        location = from.location;
        category = from.category;
        account  = from.account;
    }
    
    public var name: String;
    public var credit: Decimal;
    public var debit: Decimal;
    public var date: Date;
    public var location: String;
    @Relationship public var category: SubCategory?;
    @Relationship public var account: SubAccount?;
    
    var balance: Decimal {
        credit - debit
    }
    
    func validate() -> Bool {
        category != nil && account != nil;
    }
    func apply(_ to: LedgerEntry, context: ModelContext) {
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

@Model
public final class LedgerEntry : ObservableObject, Identifiable, InspectableElement, EditableElement
{
    typealias InspectorView = LedgerEntryInspect;
    typealias EditView = LedgerEntryEdit;
    typealias Snapshot = LedgerEntrySnapshot;
    
    
    
    init(name: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: SubCategory, account: SubAccount) {
        self.id = UUID()
        self.name = name
        self.credit = credit
        self.debit = debit
        self.date = date
        self.added_on = added_on;
        self.location = location
        self.category = category
        self.account = account
    }
    
    public var id: UUID;
    public var name: String;
    public var credit: Decimal;
    public var debit: Decimal;
    public var date: Date;
    public var added_on: Date;
    public var location: String;
    @Relationship public var category: SubCategory?;
    @Relationship public var account: SubAccount?;
    
    public var balance: Decimal {
        credit - debit
    }
    
    #if DEBUG
    static func exampleEntries(acc: [Account], cat: [Category]) -> [LedgerEntry] {
        /*
         I would like to have at least one of:
         1. One-to-One
         2. Many-to-One
         3. Food
         4. Groceries
         5. Health
         6. Gas
         7. Audit
         8. Pay
         */
        
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
            .init(name: "Initial Balance", credit: 10000, debit: 0, date: Date.now, location: "Bank", category: initialCat, account: savingsMain),
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
    
    static let exampleEntry = {
        LedgerEntry(name: "Example Transaction", credit: 0, debit: 100, date: Date.now, location: "Bank", category: .init("Example Sub Category", parent: .init("Example Category")), account: .init("Example Sub Account", parent: .init("Example Account")))
    }()
    #endif
}
