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
        BalanceResolver.computeBalances(accounts)
            .intoSimpleBalances()
            .filter { $0.balance > 0 }
            .sorted(using: KeyPathComparator(\.balance, order: .reverse))
    }
    
    var body: some View {
        LoadableView($balances, process: load, onLoad: { balances in
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
        })
    }
}

#Preview {
    MoneyGraph()
        .padding()
        .modelContainer(try! Containers.debugContainer())
        .frame(width: 200, height: 200)
}
