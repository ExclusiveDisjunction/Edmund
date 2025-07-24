//
//  BudgetInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct IncomeDivisionInspect : View {
    public var data: IncomeDivision
    
    public var body: some View {
        TabView {
            VStack {
                IncomeDivisionPropertiesInspect(data: data)
                Spacer()
            }.tabItem {
                Text("Properties")
            }
            
            IncomeDevotionsInspect(data: data)
                .tabItem {
                    Text("Devotions")
                }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        IncomeDivisionInspect(data: try! .getExampleBudget())
            .padding()
    }
}
