//
//  Envolope.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/6/25.
//

import Foundation
import CoreData

extension Envolope : VoidableElement, NamedElement, TransactionHolder {
    
    public var name: String {
        get { self.internalName ?? "" }
        set { self.internalName = newValue }
    }
    
    public var transactions: [LedgerEntry] {
        get {
            guard let ledger = self.ledger, let conv = ledger as? Set<LedgerEntry> else {
                return Array()
            }
            
            return Array(conv)
        }
        set {
            self.ledger = Set(newValue) as NSSet
        }
    }

    
    public func setVoidStatus(_ new: Bool) {
        guard new != isVoided else {
            return
        }
        
        if new {
            self.isVoided = true
            
            if let rawTransactions = self.ledger, let transactions = rawTransactions as? Set<LedgerEntry> {
                transactions.forEach { $0.setVoidStatus(true) }
            }
        }
        else {
            self.isVoided = false;
        }
    }
    
    public static func examples(cx: NSManagedObjectContext) {
        [
            "Checking": [
                "Bills",
                "Groceries",
                "Gas",
                "Personal"
            ],
            "Savings": [
                "Main",
                "Taxes"
            ],
            "Credit": [
                "Personal"
            ]
        ].forEach { accountName, envolopes in
            let account = Account(context: cx);
            account.name = accountName;
            
            envolopes.forEach { name in
                let envolope = Envolope(context: cx);
                envolope.name = name;
                envolope.account = account;
            }
        }
    }
}
