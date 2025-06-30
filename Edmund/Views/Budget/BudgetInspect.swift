//
//  BudgetInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

public struct BudgetInspect : View {
    public var data: BudgetInstance
    
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
    BudgetInspect(data: .getExampleBudget())
        .modelContainer(Containers.debugContainer)
        .padding()
}
