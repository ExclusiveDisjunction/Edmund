//
//  AccountsTable.swift
//  Edmund
//
//  Created by Hollan on 12/21/24.
//

import SwiftUI
import SwiftData;

@Observable
class LedgerViewerVM {
    init(_ sql: EdmundSQL) {
        self.sql = sql
    }
    
    var sql: EdmundSQL;
    var trans: [LedgerEntry]?;
    
    func refresh() {
        trans = sql.getTransactions();
    }
}

struct LedgerViewer: View {
    var vm: LedgerViewerVM;
    
    var body: some View {
        VStack {
            if let data = vm.trans {
                Table(data) {
                    TableColumn("Memo", value: \.inner.memo).width(130)
                    TableColumn("Credits") { item in
                        Text(item.inner.credit, format: .currency(code: "USD"))
                    }.width(50)
                    TableColumn("Debits") { item in
                        Text(item.inner.debit, format: .currency(code: "USD"))
                    }.width(50)
                    TableColumn("Date") { item in
                        Text(item.inner.date, style: .date)
                    }.width(100)
                    TableColumn("Location", value: \.inner.location)
                    TableColumn("Category") { item in
                        SubCategoryViewer(category: item.category)
                    }
                    TableColumn("Account") { item in
                        SubAccountViewer(account: item.account)
                    }
                }
            }
            else {
                Text("Please refresh the ledger to see transactions")
            }
        }.onAppear {
            vm.refresh()
        }
    }
}

#Preview {
    LedgerViewer(vm: .init(EdmundSQL.previewSQL))
}
