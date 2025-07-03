//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

/// A record into the ledger, representing a single transaction.
@Model
public final class LedgerEntry : Identifiable, SnapshotableElement {
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
    
    public func makeSnapshot() -> LedgerEntrySnapshot {
        .init(self)
    }
    public static func makeBlankSnapshot() -> LedgerEntrySnapshot {
        .init()
    }
    public func update(_ from: LedgerEntrySnapshot, unique: UniqueEngine) async {
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
    public static func exampleEntries(acc: inout BoundPairTree<Account>, cat: inout BoundPairTree<Category>) -> [LedgerEntry] {
        let transferCat  = cat.getOrInsert(parent: "Account Control", child: "Transfer" )
        let auditCat     = cat.getOrInsert(parent: "Account Control", child: "Audit"    )
        let initialCat   = cat.getOrInsert(parent: "Account Control", child: "Initial"  )
        let diCat        = cat.getOrInsert(parent: "Personal",        child: "Dining"   )
        let groceriesCat = cat.getOrInsert(parent: "Home",            child: "Groceries")
        let gasCat       = cat.getOrInsert(parent: "Car",             child: "Gas"      )
        
        let payAcc          = acc.getOrInsert(parent: "Checking", child: "Pay"        )
        let diAcc           = acc.getOrInsert(parent: "Checking", child: "DI"         )
        let creditCardAcc   = acc.getOrInsert(parent: "Checking", child: "Credit Card")
        let gasAcc          = acc.getOrInsert(parent: "Checking", child: "Gas"        )
        let groceriesAcc    = acc.getOrInsert(parent: "Checking", child: "Groceries"  )
        let savingsMain     = acc.getOrInsert(parent: "Savings",  child: "Main"       )
        let creditDI        = acc.getOrInsert(parent: "Credit",   child: "DI"         )
        let creditGroceries = acc.getOrInsert(parent: "Credit",   child: "Groceries"  )
        
        return [
            .init(name: "Initial Balance",              credit: 1000, debit: 0,   date: Date.now, location: "Bank",        category: initialCat,   account: savingsMain    ),
            .init(name: "Initial Balance",              credit: 170,  debit: 0,   date: Date.now, location: "Bank",        category: initialCat,   account: payAcc         ),
            .init(name: "'Pay' to Various",             credit: 0,    debit: 100, date: Date.now, location: "Bank",        category: transferCat,  account: payAcc         ),
            .init(name: "'Pay' to 'DI'",                credit: 35,   debit: 0,   date: Date.now, location: "Bank",        category: transferCat,  account: diAcc          ),
            .init(name: "'Pay' to 'Groceries'",         credit: 65,   debit: 0,   date: Date.now, location: "Bank",        category: transferCat,  account: groceriesAcc   ),
            .init(name: "Lunch",                        credit: 0,    debit: 20,  date: Date.now, location: "Chick-Fil-A", category: diCat,        account: creditDI       ),
            .init(name: "Groceries",                    credit: 0,    debit: 40,  date: Date.now, location: "Aldi",        category: groceriesCat, account: creditGroceries),
            .init(name: "'Groceries' to 'Credit Card'", credit: 0,    debit: 40,  date: Date.now, location: "Bank",        category: transferCat,  account: groceriesAcc   ),
            .init(name: "'DI' to 'Credit Card'",        credit: 0,    debit: 20,  date: Date.now, location: "Bank",        category: transferCat,  account: diAcc          ),
            .init(name: "Various to 'Credit Card'",     credit: 60,   debit: 0,   date: Date.now, location: "Bank",        category: transferCat,  account: creditCardAcc  ),
            .init(name: "Gas",                          credit: 0,    debit: 45,  date: Date.now, location: "7-Eleven",    category: gasCat,       account: gasAcc         ),
            .init(name: "Audit",                        credit: 0,    debit: 10,  date: Date.now, location: "Bank",        category: auditCat,     account: payAcc         )
        ]
    }
    
    /// A UI-ready filler example of a ledger entry
    @MainActor
    public static let exampleEntry = LedgerEntry(name: "Example Transaction", credit: 0, debit: 100, date: Date.now, location: "Bank", category: .init("Example Sub Category", parent: .init("Example Category")), account: .init("Example Sub Account", parent: .init("Example Account")));
}

/// The snapshot for `LedgerEntry`
@Observable
public final class LedgerEntrySnapshot : ElementSnapshot {
    public typealias Host = LedgerEntry;
    
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
    public var category: SubCategory?
    /// The associated sub account
    public var account: SubAccount?
    
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
