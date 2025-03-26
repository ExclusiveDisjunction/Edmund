//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

@Model
class LedgerEntry : ObservableObject, Identifiable
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
    
    var id: UUID;
    var memo: String;
    var credit: Decimal;
    var debit: Decimal;
    var date: Date;
    var added_on: Date;
    var location: String;
    @Relationship(deleteRule: .cascade, inverse: nil) var category: SubCategory;
    @Relationship(deleteRule: .cascade, inverse: nil) var account: SubAccount;
}
