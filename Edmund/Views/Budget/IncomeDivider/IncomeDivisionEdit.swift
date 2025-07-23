//
//  BudgetEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct IncomeDivisionEdit : View {
    public init(_ snap: IncomeDividerInstanceSnapshot) {
        self.snapshot = snap;
    }
    
    @Bindable private var snapshot: IncomeDividerInstanceSnapshot;
    
    public var body: some View {
        TabView {
            IncomeDivisionPropertiesEditor(snapshot: snapshot)
                .tabItem {
                    Text("Properties")
                }
            
            IncomeDevotionsEditor(snapshot: snapshot)
                .tabItem {
                    Text("Devotions")
                }
            
            IncomeDivisionRemainderEditor(remainder: snapshot.remainder, hasRemainder: $snapshot.hasRemainder, remainderValue: snapshot.remainderValue)
                .tabItem {
                    Text("Remainder")
                }
            
            
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        IncomeDivisionEdit(.init(try! IncomeDividerInstance.getExampleBudget()))
    }
}
