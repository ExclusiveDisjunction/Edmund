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
    init(id: UUID, memo: String, credit: Decimal, debit: Decimal, date: Date, added_on: Date, location: String, category: String, sub_category: String, tender: String, sub_tender: String) {
        self.id = id
        self.memo = memo
        self.credit = credit
        self.debit = debit
        self.t_date = date
        self.added_on = added_on;
        self.location = location
        self.category = category
        self.sub_category = sub_category
        self.account = tender
        self.sub_account = sub_tender
    }
    
    public var id: UUID;
    public var memo: String;
    public var credit: Decimal;
    public var debit: Decimal;
    public var t_date: Date;
    public var added_on: Date;
    public var location: String;
    public var category: String;
    public var sub_category: String;
    public var account: String;
    public var sub_account: String;
}

public struct AccountPair : Hashable {
    public static func == (lhs: AccountPair, rhs: AccountPair) -> Bool {
        return lhs.account == rhs.account && lhs.sub_account == rhs.sub_account;
    }
    
    init() {
        self.account = "";
        self.sub_account = "";
    }
    init(account: String, sub_account: String) {
        self.account = account;
        self.sub_account = sub_account;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(account)
        hasher.combine(sub_account)
    }
    
    var account: String;
    var sub_account: String;
    
    
}
