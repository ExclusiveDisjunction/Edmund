//
//  EdmundSQL.swift
//  Edmund
//
//  Created by Hollan on 1/8/25.
//

import SQLite
import SQLite3
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@Observable
class EdmundSQL {
    init(_ conn: Connection) throws {
        self.conn = conn
        try self.sanityCheck()
    }
    
    private func sanityCheck() throws {
        try Account.createTable(db: conn)
        try SubAccount.createTable(db: conn)
        try Category.createTable(db: conn)
        try SubCategory.createTable(db: conn)
        try RawLedgerEntry.createTable(db: conn)
    }
    
    static var previewSQL: EdmundSQL {
        do {
            return try EdmundSQL(try .init(.inMemory))
        }
        catch {
            fatalError("unable to make a default sql")
        }
    }
    
    var conn: Connection
    
    var isInMemory: Bool? {
        do {
            for row in try conn.prepare("PRAGMA database_list") {
                if let filePath = row[2] as? String {
                    if filePath.isEmpty || filePath == ":memory:" {
                        return true;
                    } else {
                        return false;
                    }
                }
            }
            
            return false;
        }
        catch {
            return nil;
        }
    }
    func moveToFile(path: String) throws{
        let new_conn = try Connection(path)
        sqlite3_backup_init(new_conn.handle, "main", conn.handle, "main").map { backup in
            sqlite3_backup_step(backup, -1)
            sqlite3_backup_finish(backup)
        }
        conn = new_conn
    }
    
    func getAccounts() -> [Account]? {
        do {
            var result: [Account] = [];
            for target in try conn.prepare(Account.table) {
                result.append(
                    .init(target[Account.name_col])
                )
            }
            
            return result
        }
        catch {
            return nil;
        }
    }
    
    func getSubAccounts() -> [SubAccount]? {
        do {
            var result: [SubAccount] = [];
            for target in try conn.prepare(SubAccount.table) {
                result.append(
                    .init(
                        target[SubAccount.name_col],
                        parent: .init(target[SubAccount.parent_col]),
                        col_id: target[SubAccount.id_col]
                    )
                )
            }
            return result
        }
        catch {
            return nil;
        }
    }
    func getSubAccsByID() -> Dictionary<Int64, SubAccount>? {
        if let sub_accs = getSubAccounts() {
            return sub_accs.reduce(into: [:]) {
                $0[$1.col_id] = $1
            }
        }
        else {
            return nil;
        }
    }
    
    func getCategories() -> [Category]? {
        do {
            var result: [Category] = [];
            for target in try conn.prepare(Category.table) {
                result.append(
                    .init(target[Category.name_col])
                )
            }
            
            return result
        }
        catch {
            return nil;
        }
    }
    func getSubCategories() -> [SubCategory]? {
        do {
            var result: [SubCategory] = [];
            for target in try conn.prepare(SubCategory.table) {
                result.append(
                    .init(
                        target[SubCategory.name_col],
                        parent: .init(target[SubCategory.parent_col]),
                        col_id: target[SubCategory.id_col]
                    )
                )
            }
            return result
        }
        catch {
            return nil;
        }
    }
    func getSubCatsByID() -> Dictionary<Int64, SubCategory>? {
        if let sub_accs = getSubCategories() {
            return sub_accs.reduce(into: [:]) {
                $0[$1.col_id] = $1
            }
        }
        else {
            return nil;
        }
    }
    
    func getTransactions() -> [LedgerEntry]? {
        if let cats = getSubCatsByID(), let accs = getSubAccsByID(), let trans = getRawTransactions() {
            return trans.reduce(into: []) {
                $0.append(
                    .init(
                        inner: $1,
                        category: cats[$1.subCatID, default: SubCategory("", parent: .init()) ],
                        account: accs[$1.subAccID, default: SubAccount("", parent: .init()) ]
                    )
                )
            }
        }
        else {
            return nil
        }
        
    }
    func getRawTransactions() -> [RawLedgerEntry]? {
        do {
            var result: [RawLedgerEntry] = [];
            for trans in try conn.prepare(RawLedgerEntry.table) {
                result.append(
                    .init(
                        t_id: trans[RawLedgerEntry.t_id_col],
                        memo: trans[RawLedgerEntry.memo_col],
                        credit: trans[RawLedgerEntry.credit_col],
                        debit: trans[RawLedgerEntry.debit_col],
                        date: trans[RawLedgerEntry.date_col],
                        location: trans[RawLedgerEntry.location_col],
                        subCatID: trans[RawLedgerEntry.cat_col],
                        subAccID: trans[RawLedgerEntry.acc_col]
                    )
                )
            }
            
            return result
        }
        catch {
            return nil;
        }
    }
}

struct EdmundDocument : FileDocument {
    
    static var readableContentTypes: [UTType] = [ .database ]
    
    var data: EdmundSQL;
    var path: String;
    
    init() {
        do {
            data = try .init(try .init(.inMemory))
            path = "";
        }
        catch {
            fatalError("Could not create database in memory")
        }
    }
    init(configuration: ReadConfiguration) throws {
        guard let path = configuration.file.filename else{
            throw CocoaError(.fileNoSuchFile)
        }
        
        self.data = try .init(
            Connection(path)
        )
        self.path = path;
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        //If the file is in memory, we need to save it to a path.
        if let inMemory = data.isInMemory {
            if inMemory {
                try data.moveToFile(path: path)
            }
        }
        else {
            throw CocoaError(.fileNoSuchFile)
        }
        
        //Clean up database
        
        let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
        return FileWrapper(regularFileWithContents: fileData)
    }
    
    
}
