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
                Text(item.date, style: .date)
            }.width(100)
            TableColumn("Location", value: \.location)
            TableColumn("Category") { item in
                NamedPairViewer(pair: item.category)
            }
            TableColumn("Account") { item in
                NamedPairViewer(pair: item.account)
            }
        }
    }
}

#Preview {
    LedgerTable()
}
