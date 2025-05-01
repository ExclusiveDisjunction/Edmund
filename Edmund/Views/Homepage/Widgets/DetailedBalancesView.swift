//
//  DetailedBalancesView.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import SwiftData
import EdmundCore

fileprivate struct DetailedBalance : Identifiable {
    init(_ name: String, _ balance: Decimal, children: [DetailedBalance]? = nil) {
        self.name = name
        self.balance = balance
        self.id = UUID()
        self.children = children
    }
    
    var id: UUID
    var name: String;
    var balance: Decimal;
    var children: [DetailedBalance]?;
}

struct DetailedBalancesView : View {
    @Query private var accounts: [Account];
    @State private var loadedBalances: [DetailedBalance]? = nil;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func loadBalances() -> [DetailedBalance] {
        let rawBalances = BalanceResolver.computeSubAccountBalances(accounts);
        let transformed = rawBalances.map { balance in
            let children = balance.value.map { subAccount, subBalance in
                DetailedBalance(subAccount.name, subBalance.0 - subBalance.1)
            }.sorted(
                using: KeyPathComparator(
                    \.balance,
                     order: .reverse
                )
            )
            
            return DetailedBalance(
                balance.key.name,
                children.reduce(Decimal(), {
                    $0 + $1.balance
                }),
                children: children
            )
        }
            .sorted(
                using: KeyPathComparator(
                    \.balance,
                     order: .reverse
                )
            );
        
        return transformed
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
