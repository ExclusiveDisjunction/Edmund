//
//  Tender.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import Foundation;
import SQLite

@Observable
class RawLedgerEntry : Identifiable {
    init(t_id: Int64, memo: String, credit: Double, debit: Double, date: Date, location: String, subCatID: Int64, subAccID: Int64) {
        self.t_id = t_id
        self.memo = memo
        self.credit = credit
        self.debit = debit
        self.date = date
        self.location = location
        self.subCatID = subCatID
        self.subAccID = subAccID
    }
    
    var id: UUID = UUID()
    var t_id: Int64;
    var memo: String;
    var credit: Double;
    var debit: Double;
    var date: Date;
    var location: String;
    var subCatID: Int64;
    var subAccID: Int64;
    
    static let table = Table("ledger")
    static let t_id_col = SQLite.Expression<Int64>("t_id")
    static let memo_col = SQLite.Expression<String>("memo")
    static let credit_col = SQLite.Expression<Double>("credit")
    static let debit_col = SQLite.Expression<Double>("debit")
    static let date_col = SQLite.Expression<Date>("date")
    static let location_col = SQLite.Expression<String>("location")
    static let cat_col = SQLite.Expression<Int64>("sub_category")
    static let acc_col = SQLite.Expression<Int64>("sub_account")
    
    static func createTable(db: Connection) throws {
        try db.run(table.create { t in
            t.column(t_id_col, primaryKey: .autoincrement)
            t.column(memo_col)
            t.column(credit_col)
            t.column(debit_col)
            t.column(date_col)
            t.column(location_col)
            t.column(cat_col)
            t.column(acc_col)
            t.foreignKey(cat_col, references: SubCategory.table, SubCategory.id_col, delete: .cascade)
            t.foreignKey(acc_col, references: SubAccount.table, SubAccount.id_col, delete: .cascade)
        })
    }
}

@Observable
class LedgerEntry : Identifiable
{
    init(inner: RawLedgerEntry, category: SubCategory, account: SubAccount) {
        self.inner = inner
        self.category = category
        self.account = account
        self.id = UUID();
    }
    
    var id: UUID;
    var inner: RawLedgerEntry;
    var category: SubCategory;
    var account: SubAccount;
}
