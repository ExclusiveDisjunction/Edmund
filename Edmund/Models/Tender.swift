//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftData;
import Foundation;

@Model
public class LedgerEntry : Identifiable
{
    init(id: UUID, memo: String, credit: Decimal, debit: Decimal, date: Date, location: String, category: String, sub_category: String? = nil, tender: String, sub_tender: String? = nil) {
        self.id = id
        self.memo = memo
        self.credit = credit
        self.debit = debit
        self.date = date
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
    public var date: Date;
    public var location: String;
    public var category: String;
    public var sub_category: String?;
    public var tender: String;
    public var sub_tender: String?;
}
