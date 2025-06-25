//
//  BalanceVerifier.swift
//  Edmund
//
//  Created by Hollan on 5/12/25.
//

import SwiftUI
import SwiftData

struct BalanceVerifier: View {
    @Query private var accounts: [Account];
    
    @State private var selection: BalanceVerifyRow.ID?; //only used for user experience
    @State private var inspecting: BalanceVerifyRow?;
    @State private var rows: [BalanceVerifyRow] = [];
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        let balances = BalanceResolver.computeBalances(accounts);
        
        self.rows = balances.map { BalanceVerifyRow(account: $0.key, balance: $0.value.0 - $0.value.1) }
    }
    
    @ViewBuilder
    private var refreshButton: some View {
        Button(action: refresh) {
            Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
        }
    }
    
    @ViewBuilder
    private var expanded: some View {
        Table(rows, selection: $selection) {
            TableColumn("Account") { item in
                Text(item.name)
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
        }.contextMenu(forSelectionType: BalanceVerifyRow.ID.self) { selection in
            refreshButton
            
            if let id = selection.first, let row = rows.first(where: { $0.id == id } ), selection.count == 1 {
                Button("Closer Look", action: {
                    inspecting = row
                })
            }
        }
    }
    
    @ViewBuilder
    private var compact: some View {
        List(rows, selection: $selection) { row in
            HStack {
                Text(row.name)
                Spacer()
                BalanceStatusText(data: row.absVariance)
            }.swipeActions(edge: .trailing) {
                Button(action: { inspecting = row } ) {
                    Label("Edit", systemImage: "pencil")
                }.tint(.green)
            }.onTapGesture(count: 2) {
                self.inspecting = row;
            }
        }
    }
    
    var body: some View {
        VStack {
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                expanded
            }
        }.navigationTitle("Balance Verification")
            .task { refresh() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    refreshButton
                }
            }.padding()
            .sheet(item: $inspecting) { row in
                BalanceVerifyRowEdit(over: row, isSheet: true)
                    .padding()
            }
    }
}

#Preview {
    BalanceVerifier()
        .modelContainer(Containers.debugContainer)
        .navigationTitle("Balance Verification")
}
