//
//  ChoiceRenderer.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI

struct ChoiceRenderer : View {
    let choice: WidgetChoice
    
    var body: some View {
        VStack {
            if choice != .none {
                HStack {
                    Text(choice.display)
                        .font(.headline)
                    Spacer()
                }
                switch choice {
                    case .bills: UpcomingBillsView()
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
    DebugContainerView {
        ChoiceRenderer(choice: .simpleBalances)
            .padding()
    }
}
