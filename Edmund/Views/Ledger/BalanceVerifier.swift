//
//  BalanceVerifier.swift
//  Edmund
//
//  Created by Hollan on 5/12/25.
//

import SwiftUI
import SwiftData
import EdmundCore

@Observable
class BalanceVerifyRow : Identifiable {
    init(account: Account, balance: Decimal) {
        self.id = UUID();
        self.account = account;
        self.balance = balance
        self.expectedBalance = .init(rawValue: balance)
    }
    
    let id: UUID
    let account: Account;
    var name: String {
        account.name
    }
    var expectedBalance: CurrencyValue;
    let balance: Decimal;
    
    var variance: Decimal {
        balance - expectedBalance.rawValue
    }
    var absVariance : Decimal {
        abs(balance) - abs(expectedBalance.rawValue)
    }
}

struct BalanceVerifier: View {
    @Query private var accounts: [Account];
    
    @State private var rows: [BalanceVerifyRow] = [];
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        let balances = BalanceResolver.computeBalances(accounts);
        
        self.rows = balances.map { BalanceVerifyRow(account: $0.key, balance: $0.value.0 - $0.value.1) }
    }
    
    var body: some View {
        VStack {
            Table($rows) {
                TableColumn("Account") { $item in
                    Text(item.name)
                }
                TableColumn("Balance") { $item in
                    Text(item.balance, format: .currency(code: currencyCode))
                }
                TableColumn("Expected") { $item in
                    CurrencyField(item.expectedBalance)
                }
                TableColumn("Variance") { $item in
                    Text(item.variance, format: .currency(code: currencyCode))
                }
                TableColumn("Status") { $row in
                    Text(row.absVariance == 0 ? "Balanced" : row.absVariance > 0 ? "Over" : "Under")
                }
            }
        }.navigationTitle("Balance Verification")
            .task { refresh() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: refresh) {
                        Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                    }
                }
            }.padding()
    }
}

#Preview {
    BalanceVerifier()
        .modelContainer(Containers.debugContainer)
        .padding()
        .navigationTitle("Balance Verification")
}
