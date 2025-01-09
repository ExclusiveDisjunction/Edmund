//
//  Accounts.swift
//  Edmund
//
//  Created by Hollan on 1/8/25.
//

import Foundation
import SwiftUI
import SQLite

@Observable
class Account : Identifiable {
    convenience init() {
        self.init("")
    }
    init(_ name: String) {
        self.name = name;
    }
    
    var id: UUID = UUID();
    var name: String;
    
    static let table = Table("accounts")
    static let name_col = SQLite.Expression<String>("name")
    
    static func createAccountsTable(db: Connection) throws {
        try db.run(table.create { t in
            t.column(name_col, primaryKey: true)
        })
    }
}

@Observable
class SubAccount : Identifiable {
    init(_ name: String, parent: Account, col_id: Int64 = 0) {
        self.name = name
        self.parent = parent
        self.col_id = col_id
    }
    
    var id: UUID = UUID();
    var col_id: Int64;
    var name: String;
    var parent: Account;
    
    static let table = Table("sub_accounts")
    static let name_col = SQLite.Expression<String>("name")
    static let id_col = SQLite.Expression<Int64>("id")
    static let parent_col = SQLite.Expression<String>("parent")
    
    static func createSubAccountsTable(db: Connection) throws {
        try db.run(table.create(ifNotExists: true) {
            $0.column(id_col, primaryKey: .autoincrement)
            $0.column(name_col)
            $0.column(parent_col)
            $0.unique(parent_col, name_col)
            $0.foreignKey(parent_col, references: Account.table, Account.name_col, update: .cascade, delete: .cascade)
        })
    }
}
