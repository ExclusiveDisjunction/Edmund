//
//  BudgetInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

struct BudgetInspect : View {
    var data: BudgetInstance
    
    var body: some View {
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
