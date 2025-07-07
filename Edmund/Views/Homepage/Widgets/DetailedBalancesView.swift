//
//  DetailedBalancesView.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct DetailedBalancesView : View {
    @Query private var accounts: [Account];
    @State private var loadedBalances: [DetailedBalance]? = nil;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    let cmp = KeyPathComparator(\DetailedBalance.balance, order: .reverse)
    private func loadBalances() -> [DetailedBalance] {
        BalanceResolver.computeSubBalances(accounts)
            .intoDetailedBalances()
            .sortedByBalances();
    }
    
    var body: some View {
        LoadableView($loadedBalances, process: loadBalances, onLoad: { balances in
            List(balances, children: \.children) { account in
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
        DetailedBalancesView()
            .padding()
            .frame(width: 300, height: 200)
    }
}
