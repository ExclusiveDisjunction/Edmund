//
//  Envolope.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/6/25.
//

import Foundation

extension Envolope : VoidableElement {
    
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
}
