//
//  BudgetInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct BudgetInspect : View {
    public var data: IncomeDividerInstance
    
    public var body: some View {
        TabView {
            BudgetPropertiesInspect(data: data)
                .tabItem {
                    Text("Properties")
                }
            
            BudgetDevotionsInspect(data: data)
                .tabItem {
                    Text("Devotions")
                }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        BudgetInspect(data: try! .getExampleBudget())
            .padding()
    }
}
