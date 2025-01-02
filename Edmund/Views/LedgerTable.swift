//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;

struct LedgerTable: View {
    @Query(sort: \LedgerEntry.added_on, order: .reverse) var data: [LedgerEntry];
    
    var body: some View {
        Table(data) {
            TableColumn("Memo", value: \.memo).width(130)
            TableColumn("Credits") { item in
                Text(item.credit, format: .currency(code: "USD"))
            }.width(50)
            TableColumn("Debits") { item in
                Text(item.debit, format: .currency(code: "USD"))
            }.width(50)
            TableColumn("Date") { item in
                Text(item.t_date, style: .date)
            }.width(100)
            TableColumn("Location", value: \.location)
            TableColumn("Category") { (item: LedgerEntry) in
                NamedPairViewer(acc: item.category_pair)
            }
            TableColumn("Account") { item in
                NamedPairViewer(acc: item.account_pair)
            }
        }
    }
}

#Preview {
    LedgerTable()
}
