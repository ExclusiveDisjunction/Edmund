//
//  Auditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/22/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct Auditor : View {
    @Query private var accounts: [Account];
    @State private var auditRows: [AccountsAuditorRow] = [];
    @State private var creditRows: [CreditCardRow] = [];
    
    private func refresh() {
        let balances = BalanceResolver.computeBalances(accounts);
        
        self.auditRows = balances.map { AccountsAuditorRow(account: $0.key, balance: $0.value.0 - $0.value.1) }
        
        self.creditRows = balances.filter { $0.key.creditLimit != nil }
            .map { bal in
                CreditCardRow(
                    account: bal.key,
                    balance: bal.value.1 - bal.value.0
                )
            }
    }
    
    var body: some View {
        VStack {
            TabView {
                AccountsAuditor(rows: $auditRows)
                    .tabItem {
                        Label("Accounts", systemImage: "dollarsign")
                    }
                
                CreditCardHelper(rows: $creditRows)
                    .tabItem {
                        Label("Credit Cards", systemImage: "creditcard")
                    }
            }
        }.padding()
            .navigationTitle("Auditor")
            .onAppear(perform: refresh)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: refresh) {
                        Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                    }
                }
                
                #if os(iOS)
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
                #endif
            }
    }
}

#Preview {
    DebugContainerView {
        Auditor()
    }
}
