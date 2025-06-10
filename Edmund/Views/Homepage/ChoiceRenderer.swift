//
//  ChoiceRenderer.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI
import EdmundCore

struct ChoiceRenderer : View {
    let choice: WidgetChoice
    
    var body: some View {
        VStack {
            if choice != .none {
                HStack {
                    Text(choice.name)
                        .font(.headline)
                    Spacer()
                }
                switch choice {
                    case .bills: UpcomingBillsView()
                    case .detailedBalances: DetailedBalancesView()
                    case .simpleBalances: SimpleBalancesView()
                    case .moneyGraph: MoneyGraph()
                    //case .payday: PaydayWidget()
                    case .spendingGraph: SpendingGraph()
                    case .none: EmptyView()
                }
                Spacer()
            }
            else {
                Spacer()
            }
        }
    }
}

#Preview {
    ChoiceRenderer(choice: .detailedBalances)
        .padding()
        .modelContainer(Containers.debugContainer)
}
