//
//  AllAccountsViewEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

struct AllNamedPairViewEdit<T> : View where T: BoundPairParent, T: PersistentModel, T.C.P == T {
    @Query private var targets: [T];
    @Query private var children: [T.C];
    
    @State private var selected: T?;
    @State private var tableSelected: T.ID?;
    @State private var selectedChild: T.C?;
    @State private var tableSelectedChild: T.C.ID?;
    @State private var showAlert = false;
    
#if os(macOS)
    @State private var showPresenter: Bool = true;
#else
    @State private var showPresenter: Bool = false;
#endif
    
    @Environment(\.modelContext) private var modelContext;
    
    private func add_parent() {
        let parent = T.init()
        modelContext.insert(parent)
        
        selected = parent 
    }
    private func add_child() {
        if let parent = targets.first(where: {$0.id == tableSelected}) {
            let child = T.C.init()
            
            child.parent = parent
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
        
        if let parent = targets.first(where: {$0.id == parentID} ) {
            if let childID = tableSelectedChild, let child = parent.children.first(where: {$0.id == childID} ) {
                modelContext.delete(child)
            }
            else {
                modelContext.delete(parent)
            }
        }
    }
    private func remove_many_child(_ id: Set<T.C.ID>) {
        let elements = children.filter { id.contains($0.id) }
        
        for element in elements {
            modelContext.delete(element)
        }
    }
    private func remove_many_parent(_ id: Set<T.ID>) {
        let parent = targets.filter { id.contains($0.id) }
        
        for element in parent {
            modelContext.delete(element)
        }
    }
    
    var body: some View {
        Table(targets, selection: $tableSelected) {
            TableColumn("Name") { target in
                Text(target.name)
            }
        }.padding(.trailing).frame(minWidth: 300, idealWidth: 350)
        .contextMenu(forSelectionType: T.ID.self) { selection in
            Button(role: .destructive) {
                withAnimation {
                    remove_many_parent(selection)
                }
            } label: {
                Text("Delete")
            }
        }.inspector(isPresented: $showPresenter, content: {
            VStack {
                if let selected = targets.first(where: {$0.id == tableSelected}) {
                    Text("\(T.kind.subNamePlural())")
                    
                    Table(selected.children, selection: $tableSelectedChild) {
                        TableColumn("Name") { value in
                            Text(value.name)
                        }
                    }.contextMenu(forSelectionType: T.C.ID.self) { selection in
                        Button(role: .destructive) {
                            withAnimation {
                                remove_many_child(selection)
                            }
                        } label: {
                            Text("Delete")
                        }
                    }
                }
                else {
                    Spacer()
                    Text("Please select an \(T.kind.rawValue) to view it's \(T.kind.subNamePlural()).").italic().font(.subheadline).multilineTextAlignment(.center)
                    Spacer()
                }
            }.padding(.leading).inspectorColumnWidth(min: 150, ideal: 200, max: 300)
        }).padding()
        .navigationTitle(T.kind.pluralized())
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Button(action: {
                        withAnimation {
                            add_parent()
                        }
                    }) {
                        Text(T.kind.rawValue)
                    }
                    Button(action: {
                        withAnimation {
                            add_child()
                        }
                    }) {
                        Text(T.kind.subName())
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }.help("Add a \(T.kind.rawValue)")
                
                Button(action: {
                    withAnimation {
                        edit_selected()
                    }
                }) {
                    Label("Edit", systemImage: "pencil")
                }.help("Edit the current \(T.kind.rawValue)")
                
                Button(action: {
                    withAnimation {
                        remove_selected()
                    }
                }) {
                    Label("Remove", systemImage: "trash").foregroundStyle(.red)
                }.help("Remove the current \(T.kind.rawValue)")
                
                Button(action: {
                    withAnimation {
                        showPresenter.toggle()
                    }
                }) {
                    Label(showPresenter ? "Hide Details" : "Show Details", systemImage: "sidebar.right")
                }
            }
        }
        .alert("Error", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text("Please select a \(T.kind.rawValue) to add a \(T.kind.subName()).")
        })
        .sheet(item: $selected) { item in
            NamedPairParentEditor(target: item)
        }
        .sheet(item: $selectedChild) { item in
            NamedPairChildEditor(target: item)
        }
    }
}

#Preview {
    AllNamedPairViewEdit<Category>().modelContainer(ModelController.previewContainer)
}
