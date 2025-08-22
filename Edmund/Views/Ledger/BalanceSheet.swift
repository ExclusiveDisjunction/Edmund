//
//  BalanceSheet.swift
//  Edmund
//
//  Created by Hollan on 12/31/24.
//

import SwiftUI
import SwiftData
import EdmundCore

/// A top level view to display all accounts, their balances, and then the sub balances within.
struct BalanceSheet: View {
    @Query private var accounts: [Account];
    
    @State private var computed: [SimpleBalance]? = nil;
    @State private var selection: Set<SimpleBalance.ID> = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        withAnimation {
            computed = nil;
        }
    }
    private func computeBalances() -> [SimpleBalance] {
        BalanceResolver(accounts)
            .computeBalances()
            .intoSimpleBalances()
    }
    
    var body: some View {
        LoadableView($computed, process: computeBalances, onLoad: { computed in
            Table(computed, selection: $selection) {
                TableColumn("Account") { balance in
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text(balance.name)
                            Spacer()
                            Text(balance.balance, format: .currency(code: currencyCode))
                        }
                    }
                    else {
                        Text(balance.name)
                    }
                }
                
                TableColumn("Money In") { balance in
                    Text(balance.credit, format: .currency(code: currencyCode))
                }.alignment(.numeric)
                
                TableColumn("Money Out") { balance in
                    Text(balance.debit, format: .currency(code: currencyCode))
                }.alignment(.numeric)
                
                TableColumn("Balance") { balance in
                    Text(balance.balance, format: .currency(code: currencyCode))
                }.alignment(.numeric)
            }
        }).toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
                }
            }
        }
        .navigationTitle("Balance Sheet")
        .padding()
    }
}

#Preview {
    DebugContainerView {
        BalanceSheet()
            .frame(width: 500, height: 400)
    }
}
