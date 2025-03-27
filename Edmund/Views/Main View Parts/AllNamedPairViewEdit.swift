//
//  AllAccountsViewEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct AllNamedPairViewEdit<T> : View where T: BoundPairParent, T: PersistentModel {
    @Query private var targets: [T];
    @Query private var children: [T.C];
    
    @State private var selected: T?;
    @State private var tableSelected: T.ID?;
    @State private var selectedChild: T.C?;
    @State private var tableSelectedChild: T.C.ID?;
    @State private var showAlert = false;
    
    @Environment(\.modelContext) private var modelContext;
    
    private func add_parent() {
        let parent = T.init()
        modelContext.insert(parent)
        
        selected = parent 
    }
    private func add_child() {
        if let parent = targets.first(where: {$0.id == tableSelected}) {
            let child = T.C.init()
            
            parent.bound_pairs.append(child)
            child.pair_parent = parent
            modelContext.insert(child)
            
            selectedChild = child
        }
        else {
            showAlert = true
        }
    }
    private func edit_selected() {
        guard let parentID = tableSelected else { return }
        
        if let childID = tableSelectedChild {
            self.selectedChild = children.first(where: {$0.id == childID } );
        }
        else {
            self.selected = targets.first(where: {$0.id == parentID } );
        }
    }
    private func remove_selected() {
        guard let parentID = tableSelected else { return }
        
        if let childID = tableSelectedChild {
            if let child = children.first(where: {$0.id == childID } ) {
                modelContext.delete(child)
            }
        }
        else {
            if let parent = targets.first( where: {$0.id == parentID } ) {
                modelContext.delete(parent)
            }
        }
    }
    private func remove_many_child(_ id: Set<T.C.ID>) {
        
    }
    
    var body: some View {
        HSplitView {
            Table(targets, selection: $tableSelected) {
                TableColumn("Name") { target in
                    Text(target.name)
                }
            }.padding(.trailing).frame(minWidth: 300, idealWidth: 350)
            
            if let selected = targets.first(where: {$0.id == tableSelected}) {
                VStack {
                    Text("\(T.kind.subNamePlural())")
                    
                    Table(selected.bound_pairs, selection: $tableSelectedChild) {
                        TableColumn("Name") { value in
                            Text(value.child_name)
                        }
                    }.contextMenu(forSelectionType: T.C.ID.self) { selection in
                        Button(role: .destructive) {
                            
                        } label: {
                            Text("Delete")
                        }
                    }
                }.padding(.leading).frame(minWidth: 200)
            }
            else {
                VStack {
                    Spacer()
                    Text("Please select an \(T.kind.rawValue) to view it's \(T.kind.subNamePlural()).").italic().font(.subheadline).multilineTextAlignment(.center)
                    Spacer()
                }.padding(.leading).frame(minWidth: 200)
            }
        }.padding()
        .navigationTitle(T.kind.pluralized())
        .toolbar {
            Menu {
                Button(action: add_parent) {
                    Text(T.kind.rawValue)
                }
                Button(action: add_child) {
                    Text(T.kind.subName())
                }
            } label: {
                Label("Add", systemImage: "plus")
            }.help("Add a \(T.kind.rawValue)")
            
            Button(action: edit_selected) {
                Label("Edit", systemImage: "pencil")
            }.help("Edit the current \(T.kind.rawValue)")
            
            Button(action: remove_selected) {
                Label("Remove", systemImage: "trash").foregroundStyle(.red)
            }.help("Remove the current \(T.kind.rawValue)")
            
            
        }
        .alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please select a \(T.kind.rawValue) to add a \(T.kind.subName()).")
        })
    }
}

#Preview {
    AllNamedPairViewEdit<Category>().modelContainer(ModelController.previewContainer)
}
