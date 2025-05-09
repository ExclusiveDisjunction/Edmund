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
                    case .moneyGraph:
                        Text("Work in progress")
                    case .payday:
                        Text("Work in progress")
                    case .spendingGraph:
                        Text("Work in progress")
                    case .none:
                        EmptyView()
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
