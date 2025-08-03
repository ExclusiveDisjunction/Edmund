//
//  BalanceVerification.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct CreditCardHelper: View {
    @Binding var rows: [CreditCardRow];
    @State private var inspecting: CreditCardRow?;
    @State private var selection: CreditCardRow.ID?; //Only used to let the user select a row
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @ViewBuilder
    var expanded: some View {
        Table(rows, selection: $selection) {
            TableColumn("Account") { row in
                if horizontalSizeClass == .compact {
                    HStack {
                        Text(row.name)
                        Spacer()
                        BalanceStatusText(data: row.variance)
                    }.swipeActions(edge: .trailing) {
                        Button(action: {
                            inspecting = row;
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }.tint(.green)
                            .buttonStyle(.bordered)
                    }.onTapGesture(count: 2) {
                        self.inspecting = row;
                    }
                }
                else {
                    Text(row.name)
                }
            }
            TableColumn("Credit Limit") { row in
                Text(row.creditLimit, format: .currency(code: currencyCode))
            }
            TableColumn("Availiable Credit") { row in
                CurrencyField(row.avalibleCredit)
            }
            TableColumn("Expected Balance") { row in
                Text(row.expectedBalance, format: .currency(code: currencyCode))
            }
            TableColumn("Current Balance") { row in
                Text(row.balance, format: .currency(code: currencyCode))
            }
            TableColumn("Variance") { row in
                Text(row.variance, format: .currency(code: currencyCode))
            }
            TableColumn("Status") { row in
                BalanceStatusText(data: row.variance)
            }
        }.contextMenu(forSelectionType: CreditCardRow.ID.self) { selection in
            if let id = selection.first, let row = rows.first(where: { $0.id == id } ), selection.count == 1 {
                Button{
                    inspecting = row
                } label: {
                    Label("Close Look", systemImage: "magnifyingglass")
                }
            }
        }
    }

    var body: some View {
        expanded
            .sheet(item: $inspecting) { row in
                CreditCardRowEditor(over: row, isSheet: true)
                    .padding()
            }
    }
}
