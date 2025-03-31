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
    @State private var sortOrder = [KeyPathComparator(\UtilityEntry.date, order: .forward)]
    
#if os(macOS)
    @State private var showPresenter: Bool = true;
#else
    @State private var showPresenter: Bool = false;
#endif
    
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
        if let id = tableSelected {
            edit_specific(id)
        }
    }
    private func edit_specific(_ id: Utility.ID) {
        if let selected = utilities.first(where: { $0.id == id }) {
            selectedUtility = selected
        }
    }
    private func remove_utility() {
        if let selected = utilities.first(where: {$0.id == tableSelected} ) {
            modelContext.delete(selected)
        }
    }
    private func remove_specific(_ id_set: Set<Utility.ID>) {
        let targets = utilities.filter( { id_set.contains($0.id) } );
        for target in targets {
            modelContext.delete(target)
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                Table(self.utilities, selection: $tableSelected) {
                    TableColumn("Name") { util in
                        Text(util.name)
                    }
                    TableColumn("Avg. Price Per Week") { util in
                        Text(util.pricePerWeek, format: .currency(code: "USD"))
                    }
                }.frame(minWidth: 300, idealWidth: 350).contextMenu(forSelectionType: Utility.ID.self) { selection in
                    
                    if let first = selection.first {
                        Button(action: {
                            edit_specific(first)
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
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
            }.padding(.trailing).inspector(isPresented: $showPresenter, content: {
                VStack {
                    if let target = utilities.first(where: {$0.id == tableSelected }) {
                        Text("\(target.name) Datapoints").font(.headline)
                        
                        Table(target.amounts, sortOrder: $sortOrder) {
                            TableColumn("Time") { value in
                                Text(value.date.formatted(date: .abbreviated, time: .omitted))
                            }
                            TableColumn("Amount") { value in
                                Text(value.amount, format: .currency(code: "USD"))
                            }
                        }.onChange(of: sortOrder) { _, order in
                            target.amounts.sort(using: order)
                        }
                        
                        Spacer()
                    }
                    else {
                        Spacer()
                        Text("Please select a utilitiy to view its datapoints").italic().font(.subheadline).multilineTextAlignment(.center)
                        Spacer()
                    }
                }.padding(.leading).inspectorColumnWidth(min: 250, ideal: 300, max: 350)
            })
        }.padding().sheet(item: $selectedUtility, content: { utility in
            UtilityEditor(utility: utility)
        }).toolbar {
            ToolbarItemGroup {
                Button(action: add_utility) {
                    Label("Add", systemImage: "plus")
                }
                
                Button(action: edit_utility) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: remove_utility) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }
                
                Button(action: {
                    withAnimation {
                        showPresenter.toggle()
                    }
                }) {
                    Label(showPresenter ? "Hide Details" : "Show Details", systemImage: "sidebar.right")
                }
            }
        }.navigationTitle("Utilities")
    }
}

#Preview {
    AllUtilitiesViewEdit().modelContainer(ModelController.previewContainer)
}
