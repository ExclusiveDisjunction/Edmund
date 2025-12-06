//
//  BudgetEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

public struct IncomeDivisionEdit : View {
    public init(_ snap: IncomeDivisionSnapshot) {
        self.snapshot = snap;
    }
    
    @Bindable private var snapshot: IncomeDivisionSnapshot;
    
    public var body: some View {
        TabView {
            IncomeDivisionPropertiesEditor(snapshot: snapshot, isSheet: false)
                .tabItem {
                    Text("Properties")
                }
            
            IncomeDevotionsEditor(snapshot: snapshot)
                .padding()
                .tabItem {
                    Text("Devotions")
                }
            
            
        }.padding()
    }
}

#Preview {
    @Previewable @Query var income: [IncomeDivision];
    DebugContainerView {
        IncomeDivisionEdit(income[0].makeSnapshot())
    }
}
