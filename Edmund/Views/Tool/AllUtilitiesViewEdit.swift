//
//  AllUtilitiesEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct AllUtilitiesViewEdit : View {
    @Query var utilities: [Utility];
    @State private var tableSelected: Utility.ID?;
    
    private var totalPPW: Decimal {
        self.utilities.reduce(0, { $0 + $1.pricePerWeek} )
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Utilities").font(.title)
                Spacer()
            }
            
            HStack {
                Button(action: {
                    
                }) {
                    Label("Add", systemImage: "plus")
                }
                
                Button(action: {
                    
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: {
                    
                }) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }
            }
            
            Table(self.utilities, selection: $tableSelected) {
                TableColumn("Name") { util in
                    Text(util.name)
                }
                TableColumn("Avg. Price Per Week") { util in
                    Text(util.pricePerWeek, format: .currency(code: "USD"))
                }
            }
            
            HStack {
                Spacer()
                Text("Total Price Per Week:")
                Text(self.totalPPW, format: .currency(code: "USD"))
            }
        }.padding()
    }
}

#Preview {
    AllUtilitiesViewEdit().modelContainer(ModelController.previewContainer)
}
