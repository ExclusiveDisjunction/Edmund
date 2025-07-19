//
//  ChoicePicker.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/29/25.
//

import SwiftUI

enum WidgetChoice: Int, CaseIterable, Identifiable, Codable, Displayable {
    case bills = 0,
         simpleBalances = 1,
         detailedBalances = 2,
         spendingGraph = 3,
         moneyGraph = 4,
         //payday = 5,
         none = 6
    
    var display: LocalizedStringKey {
        switch self {
            case .bills:            "Upcoming Bills"
            case .simpleBalances:   "Balance Overview"
            case .detailedBalances: "Balances"
            case .spendingGraph:    "Spending Graph"
            case .moneyGraph:       "Balances Graph"
            //case .payday:           "Payday Info"
            case .none:             "None"
        }
    }
    
    var id: Self { self }
}

struct ChoicePicker : View {
    @Binding var choice: WidgetChoice;
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                Picker("", selection: _choice) {
                    ForEach(WidgetChoice.allCases, id: \.id) { choice in
                        Text(choice.display).tag(choice)
                    }
                }.padding()
                    .foregroundStyle(.primary)
            }.frame(width: reader.size.width, height: reader.size.height)
                .background(
                    RoundedRectangle(
                        cornerSize: CGSize(
                            width: 12,
                            height: 12
                        )
                    ).fill(.accent.opacity(0.33))
                )
                
        }
    }
}

#Preview {
    var choice = WidgetChoice.bills;
    let binding = Binding(get: {choice}, set: {choice = $0})
    
    ChoicePicker(choice: binding)
        .padding()
}
