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
        let result = BalanceResolver.computeSubBalances(accounts)
            .intoDetailedBalances()
            .sorted(using: cmp);
        
        for item in result {
            if var children = item.children {
                children.sort(using: cmp)
            }
        }
        
        return result
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
    DetailedBalancesView()
        .padding()
        .frame(width: 300, height: 200)
        .modelContainer(Containers.debugContainer)
}
