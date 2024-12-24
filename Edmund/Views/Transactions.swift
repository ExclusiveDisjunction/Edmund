//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;

struct TransactionBase: View {
    
    @State private var adding : [LedgerEntry] = [];
    @State private var selected: UUID?;
    
    private func add_trans() {
        adding.append(LedgerEntry(id: UUID(), memo: "", credit: 0.00, debit: 0.00, date: Date.now, added_on: Date.now, location: "", category: "", sub_category: "", tender: "", sub_tender: ""))
    }
    private func remove_trans() {
        if selected == nil { return }
        adding.removeAll(where: { $0.id == selected })
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    add_trans()
                }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    remove_trans()
                }) {
                    Image(systemName: "trash").foregroundStyle(.red)
                }.disabled(selected == nil)
            }.padding(5)
            Table($adding, selection: $selected) {
                TableColumn("Memo") { $item in
                    TextField("Memo", text: $item.memo)
                }
                TableColumn("Credit") { $item in
                    TextField("Credit", value: $item.credit, format: .currency(code: "USD"))
                }
                TableColumn("Debit") { $item in
                    TextField("Debit", value: $item.debit, format: .currency(code: "USD"))
                }
                TableColumn("Date") { $item in
                    DatePicker("Date", selection: $item.t_date, displayedComponents: .date).labelsHidden()
                }
                TableColumn("Location") { $item in
                    TextField("Location", text: $item.location)
                }
                TableColumn("Category") { $item in
                    TextField("Category", text: $item.category)
                }
                TableColumn("Sub Category") { $item in
                    TextField("Sub Category", text: $item.sub_category)
                }
                TableColumn("Tender") { $item in
                    TextField("Tender", text: $item.tender)
                }
                TableColumn("Sub Tender") { $item in
                    TextField("Sub Tender", text: $item.sub_tender)
                }
            }.padding(5)
        }
    }
}

#Preview {
    TransactionBase()
}
