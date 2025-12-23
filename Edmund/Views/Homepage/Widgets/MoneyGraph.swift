//
//  MoneyGraph.swift
//  Edmund
//
//  Created by Hollan on 5/8/25.
//

import SwiftUI
import SwiftData
import Charts

struct MoneyGraph : View {
    @State private var balances: [SimpleBalance]?;
    
    private static nonisolated func load() async throws -> [SimpleBalance] {
        try await BalanceResolver.accountSpending(using: DataStack.shared.currentContainer)
            .filter { $0.balance.balance > 0 }
    }
    
    var body: some View {
        LoadableView($balances, process: Self.load) { balances in
            if balances.isEmpty {
                Text("There is not enough information to display spending.")
                    .italic()
            }
            else {
                Chart(balances) { balance in
                    SectorMark(
                        angle: .value(
                            Text(verbatim: balance.name),
                            balance.balance.balance
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

#Preview(traits: .sampleData) {
    MoneyGraph()
        .padding()
        .frame(width: 200, height: 200)
}
