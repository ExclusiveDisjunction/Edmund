//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

@Model
public class LedgerEntry : ObservableObject, Identifiable
{
    init(memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: SubCategory, account: SubAccount) {
        self.id = UUID()
        self.memo = memo
        self.credit = credit
        self.debit = debit
        self.date = date
        self.added_on = added_on;
        self.location = location
        self.category = category
        self.account = account
    }
    
    public var id: UUID;
    public var memo: String;
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
            .init(memo: "Initial Balance", credit: 10000, debit: 0, date: Date.now, location: "Bank", category: initialCat, account: savingsMain),
            .init(memo: "Initial Balance", credit: 170, debit: 0, date: Date.now, location: "Bank", category: initialCat, account: payAcc),
            .init(memo: "'Pay' to Various", credit: 0, debit: 100, date: Date.now, location: "Bank", category: transferCat, account: payAcc),
            .init(memo: "'Pay' to 'DI'", credit: 35, debit: 0, date: Date.now, location: "Bank", category: transferCat, account: diAcc),
            .init(memo: "'Pay' to 'Groceries'", credit: 65, debit: 0, date: Date.now, location: "Bank", category: transferCat, account: groceriesAcc),
            .init(memo: "Lunch", credit: 0, debit: 20, date: Date.now, location: "Chick-Fil-A", category: diCat, account: creditDI),
            .init(memo: "Groceries", credit: 0, debit: 40, date: Date.now, location: "Aldi", category: groceriesCat, account: creditGroceries),
            .init(memo: "'Groceries' to 'Credit Card'", credit: 0, debit: 40, date: Date.now, location: "Bank", category: transferCat, account: groceriesAcc),
            .init(memo: "'DI' to 'Credit Card'", credit: 0, debit: 20, date: Date.now, location: "Bank", category: transferCat, account: diAcc),
            .init(memo: "Various to 'Credit Card'", credit: 60, debit: 0, date: Date.now, location: "Bank", category: transferCat, account: creditCardAcc),
            .init(memo: "Gas", credit: 0, debit: 45, date: Date.now, location: "7-Eleven", category: gasCat, account: gasAcc),
            .init(memo: "Audit", credit: 0, debit: 10, date: Date.now, location: "Bank", category: auditCat, account: payAcc)
        ]
    }
    
    static let exampleEntry = {
        LedgerEntry(memo: "Example Transaction", credit: 0, debit: 100, date: Date.now, location: "Bank", category: .init("Example Sub Category", parent: .init("Example Category")), account: .init("Example Sub Account", parent: .init("Example Account")))
    }()
    #endif
}
