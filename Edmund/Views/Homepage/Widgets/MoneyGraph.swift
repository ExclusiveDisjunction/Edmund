//
//  MoneyGraph.swift
//  Edmund
//
//  Created by Hollan on 5/8/25.
//

import SwiftUI
import SwiftData
import Charts
import EdmundCore

struct MoneyGraph : View {
    @Query private var accounts: [Account]
    @State private var balances: [SimpleBalance]?;
    
    private func load() -> [SimpleBalance] {
        BalanceResolver(accounts)
            .computeBalances()
            .intoSimpleBalances()
            .filter { $0.balance > 0 }
    }
    
    var body: some View {
        LoadableView($balances, process: load) { balances in
            if balances.isEmpty {
                Text("There is not enough information to display spending.")
                    .italic()
            }
            else {
                Chart(balances) { balance in
                    SectorMark(
                        angle: .value(
                            Text(verbatim: balance.name),
                            balance.balance
                        )
                    ).foregroundStyle(by:
                            .value(
                                Text(verbatim: balance.name),
                                balance.name
                            )
                    )
                }
            }
        }
    }
}

#Preview {
    DebugContainerView {
        MoneyGraph()
            .padding()
            .frame(width: 200, height: 200)
    }
}
