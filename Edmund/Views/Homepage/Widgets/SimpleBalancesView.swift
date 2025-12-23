//
//  SimpleBalancesView.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI

struct SimpleBalancesView : View {
    @State private var loadedBalances: [SimpleBalance]? = nil;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private static nonisolated func loadBalances() async throws -> [SimpleBalance] {
        try await BalanceResolver.accountSpending(using: DataStack.shared.currentContainer)
    }
    
    var body: some View {
        LoadableView($loadedBalances, process: Self.loadBalances) { balances in
            if balances.isEmpty {
                Text("There are no balances to display")
                    .italic()
            }
            else {
                List(balances) { account in
                    HStack {
                        Text(account.name)
                        Spacer()
                        Text(account.balance.balance, format: .currency(code: currencyCode))
                            .foregroundStyle(account.balance.balance < 0 ? .red : .primary)
                    }
                }
            }
        }
    }
}

#Preview(traits: .sampleData) {
    SimpleBalancesView()
        .padding()
        .frame(width: 300, height: 200)
}
