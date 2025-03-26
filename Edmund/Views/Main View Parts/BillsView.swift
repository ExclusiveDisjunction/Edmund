//
//  BillsView.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI;
import SwiftData;

struct BillsView : View {
    @State var showSimpleEdit = false;
    @State var showComplexEdit = false;
    
    
    var body: some View {
        TabView {
            AllBillsViewEdit(kind: .simple)
                .tabItem {
                    Text("Simple")
                }
            AllBillsViewEdit(kind: .complex)
                .tabItem{
                    Text("Complex")
                }
            AllUtilitiesViewEdit()
                .tabItem {
                    Text("Utilities")
                }
            
        }.padding()
    }
}

#Preview {
    BillsView().modelContainer(ModelController.previewContainer)
}
