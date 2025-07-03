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
    @Query private var accounts: [Account];
    @State private var manual: Bool = false;
    @State private var rows: [CreditCardRow] = [];
    @State private var inspecting: CreditCardRow?;
    @State private var selection: CreditCardRow.ID?; //Only used to let the user select a row
    
    @Environment(\.openWindow) private var openWindow;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("showCreditCardHelperTooltip") private var showCreditCardHelperTooltip: Bool = true;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        let balances = BalanceResolver.computeBalances(accounts).filter { $0.key.creditLimit != nil };
        
        self.rows = balances.map { bal in
            CreditCardRow(
                account: bal.key,
                balance: bal.value.1 - bal.value.0
            )
        }
    }
    
    @ViewBuilder
    var refreshButton : some View {
        Button(action: refresh) {
            Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
        }
    }
    
    @ViewBuilder
    var expanded: some View {
        Table(rows, selection: $selection) {
            TableColumn("Account") { row in
                Text(row.name)
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
            refreshButton

            if let id = selection.first, let row = rows.first(where: { $0.id == id } ), selection.count == 1 {
                Button("Closer look", action: {
                    inspecting = row
                })
            }
        }
    }
    
    @ViewBuilder
    var compact: some View {
        List(rows, selection: $selection) { row in
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
        }.contextMenu(forSelectionType: CreditCardRow.ID.self ){ selection in
            refreshButton
            
            if let id = selection.first, let row = rows.first(where: { $0.id == id } ), selection.count == 1{
                Button(action: {
                    inspecting = row;
                }) {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
    }

    var body: some View {
        VStack {
            if showCreditCardHelperTooltip {
                HStack {
                    Text("If you need assistance with this tool, please see the help topic.")
                        .italic()
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showCreditCardHelperTooltip = false
                        }
                    }) {
                        Image(systemName: "x.square")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
            
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                expanded
            }
        }.padding()
            .task { refresh() }
            .navigationTitle("Credit Card Helper")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    refreshButton
                }
            }.sheet(item: $inspecting) { row in
                CreditCardRowEditor(over: row, isSheet: true)
                    .padding()
            }
    }
}

#Preview {
    CreditCardHelper().modelContainer(try! Containers.debugContainer())
}
