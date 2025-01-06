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
    convenience init(memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: String, sub_category: String, account: String, sub_account: String) {
        self.init(memo: memo, credit: credit, debit: debit, date: date, added_on: added_on, location: location, category: .init(category, sub_category), account: .init(account, sub_account))
    }
    init(memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date = Date.now, location: String, category: CategoryPair, account: AccountPair) {
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
    @Relationship(deleteRule: .nullify, inverse: nil) var category: CategoryPair;
    @Relationship(deleteRule: .nullify, inverse: nil) var account: AccountPair;
}

@Model
class CategoryPair: Identifiable {
    init(_ category: String = "", _ sub_category: String = "") {
        self.category = category
        self.sub_category = sub_category
    }
    
    var id: UUID = UUID();
    var category: String;
    var sub_category: String;
    
    var isEmpty: Bool {
        category.isEmpty || sub_category.isEmpty
    }
}
@Model
class AccountPair: Identifiable {
    init(_ account: String = "", _ sub_account: String = "", limit: Decimal? = nil) {
        self.account = account
        self.sub_account = sub_account
        self.limit = limit
    }
    
    var id: UUID = UUID();
    var account: String;
    var sub_account: String;
    var limit: Decimal?;
    
    var isEmpty: Bool {
        account.isEmpty || sub_account.isEmpty
    }
}
