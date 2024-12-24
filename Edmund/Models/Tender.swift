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
        self.tender = tender
        self.sub_tender = sub_tender
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
    public var tender: String;
    public var sub_tender: String;
}
