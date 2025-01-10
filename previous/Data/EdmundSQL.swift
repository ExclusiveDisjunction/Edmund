//
//  EdmundSQL.swift
//  Edmund
//
//  Created by Hollan on 1/8/25.
//

import SQLite
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@Observable
class EdmundSQL {
    init(_ conn: Connection) {
        self.conn = conn
    }
    
    var conn: Connection
    
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
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        
    }
    
    static var readableContentTypes: [UTType] = [ .database ]
    
    init(configuration: ReadConfiguration) throws {
        
    }
    
    
}
