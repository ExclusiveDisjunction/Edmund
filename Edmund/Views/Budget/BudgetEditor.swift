//
//  BudgetEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

struct BudgetEditor : View {
    init(_ snap: BudgetInstanceSnapshot) {
        self.snapshot = snap;
    }
    
    @Bindable private var snapshot: BudgetInstanceSnapshot;
    
    var body: some View {
        TabView {
            BudgetPropertiesEditor(snapshot: snapshot)
                .tabItem {
                    Text("Properties")
                }
            
            BudgetDevotionsEditor(snapshot: snapshot)
                .tabItem {
                    Text("Devotions")
                }
            
            BudgetRemainderEditor(remainder: snapshot.remainder, hasRemainder: $snapshot.hasRemainder, remainderValue: snapshot.remainderValue)
                .tabItem {
                    Text("Remainder")
                }
            
            
        }.padding()
    }
}

#Preview {
    BudgetEditor(.init(BudgetInstance.getExampleBudget()))
        .modelContainer(Containers.debugContainer)
}
