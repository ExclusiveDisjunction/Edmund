//
//  SimpleBalancesView.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import SwiftData
import EdmundCoreImm

struct SimpleBalancesView : View {
    @Query private var accounts: [Account];
    @State private var loadedBalances: [SimpleBalance]? = nil;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func loadBalances() -> [SimpleBalance] {
        BalanceResolver(accounts)
            .computeBalances()
            .intoSimpleBalances()
    }
    
    var body: some View {
        LoadableView($loadedBalances, process: loadBalances, onLoad: { balances in
            List(balances) { account in
                HStack {
                    Text(account.name)
                    Spacer()
                    Text(account.balance, format: .currency(code: currencyCode))
                        .foregroundStyle(account.balance < 0 ? .red : .primary)
                }
            }
        })
    }
}

#Preview {
    DebugContainerView {
        SimpleBalancesView()
            .padding()
            .frame(width: 300, height: 200)
    }
}
