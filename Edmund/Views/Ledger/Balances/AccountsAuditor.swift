//
//  BalanceVerifier.swift
//  Edmund
//
//  Created by Hollan on 5/12/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct AccountsAuditor: View {
    @Binding var rows: [AccountsAuditorRow];
    
    @State private var selection: AccountsAuditorRow.ID? = nil; //only used for user experience
    @State private var inspecting: AccountsAuditorRow? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    private var expanded: some View {
        Table(rows, selection: $selection) {
            TableColumn("Account") { item in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(item.name)
                        Spacer()
                        BalanceStatusText(data: item.absVariance)
                    }.swipeActions(edge: .trailing) {
                        Button(action: { inspecting = item } ) {
                            Label("Edit", systemImage: "pencil")
                        }.tint(.green)
                    }.onTapGesture(count: 2) {
                        self.inspecting = item;
                    }
                }
                else {
                    Text(item.name)
                }
            }
            TableColumn("Balance") { item in
                Text(item.balance, format: .currency(code: currencyCode))
            }
            TableColumn("Expected") { item in
                CurrencyField(item.expectedBalance)
            }
            TableColumn("Variance") { item in
                Text(item.variance, format: .currency(code: currencyCode))
            }
            TableColumn("Status") { row in
                BalanceStatusText(data: row.absVariance)
            }
        }.contextMenu(forSelectionType: AccountsAuditorRow.ID.self) { selection in
            if let id = selection.first, let row = rows.first(where: { $0.id == id } ), selection.count == 1 {
                Button("Closer Look", action: {
                    inspecting = row
                })
            }
        }
    }
    
    var body: some View {
        expanded
            .sheet(item: $inspecting) { row in
                AccountsAuditorRowEdit(over: row, isSheet: true)
                    .padding()
            }
    }
}
