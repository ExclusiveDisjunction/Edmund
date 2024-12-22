//
//  LedgerModel.swift
//  Edmund
//
//  Created by Hollan on 11/4/24.
//

import Foundation
import SwiftData

class LedgerModel: ObservableObject {
    @Published var tenders: [Tender]
   // @Published var subTenders: [SubTender]
    @Published var transactions: [Ledger]
    @Published var categories: [Category]
    
    init(tenders: [Tender], transactions: [Ledger], categories: [Category]) {
        self.tenders = tenders
        self.transactions = transactions
        self.categories = categories
    }
}
