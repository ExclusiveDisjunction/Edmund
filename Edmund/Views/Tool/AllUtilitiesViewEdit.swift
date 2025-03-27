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
    @State private var selectedUtility: Utility?;
    @Environment(\.modelContext) private var modelContext;
    
    private var totalPPW: Decimal {
        self.utilities.reduce(0, { $0 + $1.pricePerWeek} )
    }
    
    private func add_utility() {
        let newUtility = Utility(name: "", amounts: [])
        
        modelContext.insert(newUtility)
        self.selectedUtility = newUtility;
    }
    private func edit_utility() {
        if let selected = utilities.first(where: {$0.id == tableSelected} ) {
            selectedUtility = selected
        }
    }
    private func remove_utility() {
        if let selected = utilities.first(where: {$0.id == tableSelected} ) {
            modelContext.delete(selected)
        }
    }
    private func remove_specific(_ id_set: Set<Utility.ID>) {
        for id in id_set {
            if let found = utilities.first(where: {$0.id == id} ) {
                modelContext.delete(found)
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Utilities").font(.title)
                Spacer()
            }
            
            HSplitView {
                VStack {
                    Table(self.utilities, selection: $tableSelected) {
                        TableColumn("Name") { util in
                            Text(util.name)
                        }
                        TableColumn("Avg. Price Per Week") { util in
                            Text(util.pricePerWeek, format: .currency(code: "USD"))
                        }
                    }.frame(minWidth: 300, idealWidth: 350).contextMenu(forSelectionType: Utility.ID.self) { selection in
                        Button(role: .destructive) {
                            remove_specific(selection)
                        } label: {
                            Label("Delete", systemImage: "trash").foregroundStyle(.red)
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("Total Price Per Week:")
                        Text(self.totalPPW, format: .currency(code: "USD"))
                    }
                }.padding(.trailing)
                
                if let target = utilities.first(where: {$0.id == tableSelected }) {
                    VStack {
                        Text("\(target.name) Datapoints").font(.headline)
                        
                        List(target.amounts, id: \.id) { value in
                            Text(value.amount, format: .currency(code: "USD"))
                        }
                        
                        Spacer()
                    }.padding(.leading).frame(minWidth: 200)
                }
                else {
                    VStack {
                        Spacer()
                        Text("Please select a utilitiy to view its datapoints").italic().font(.subheadline).multilineTextAlignment(.center)
                        Spacer()
                    }.padding()
               }
            }.frame(minHeight: 300)
        }.padding().sheet(item: $selectedUtility, content: { utility in
            UtilityEditor(utility: utility)
        }).toolbar {
            HStack {
                Button(action: add_utility) {
                    Label("Add", systemImage: "plus")
                }
                
                Button(action: edit_utility) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: remove_utility) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }
            }
        }
    }
}

#Preview {
    AllUtilitiesViewEdit().modelContainer(ModelController.previewContainer)
}
