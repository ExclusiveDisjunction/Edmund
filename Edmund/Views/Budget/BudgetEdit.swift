//
//  BudgetEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct BudgetEdit : View {
    public init(_ snap: BudgetInstanceSnapshot) {
        self.snapshot = snap;
    }
    
    @Bindable private var snapshot: BudgetInstanceSnapshot;
    
    public var body: some View {
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
    BudgetEdit(.init(try! BudgetInstance.getExampleBudget()))
        .modelContainer(try! Containers.debugContainer())
}
