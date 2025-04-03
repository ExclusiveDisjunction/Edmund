//
//  AllAccountsViewEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

@Observable
class AllPairsHelper<T> : Identifiable where T: BoundPairParent {
    init(_ target: T) {
        self.target = target
        self.id = UUID()
    }
    
    var target: T
    var id: UUID
    var childrenShown: Bool = false
    
    var children: [T.C] {
        target.children.sorted(by: { $0.name < $1.name } )
    }
}

struct AllNamedPairViewEdit<T> : View where T: BoundPairParent, T: PersistentModel, T.C.P == T {
    
    
    @Query private var parents: [T];
    @Query private var children: [T.C];
    @State private var expandAll: Bool = false;
    @State private var collapseAll: Bool = false;
    
    private var helpers: [AllPairsHelper<T>] {
        parents.sorted(by: { $0.name < $1.name } ).map { AllPairsHelper( $0 ) }
    }
    
    @State private var selected: T?;
    @State private var selectedChild: T.C?;
    
    @Environment(\.modelContext) private var modelContext;
    
    private func add_parent() {
        let parent = T.init()
        modelContext.insert(parent)
        
        selected = parent 
    }
    private func add_child(_ parent: T.ID) {
        guard let parent = parents.first(where: {$0.id == parent }) else { return }
        let child = T.C.init()
        
        child.parent = parent
        modelContext.insert(child)
        
        selectedChild = child
    }
    private func remove_parent(_ id: T.ID) {
        guard let target = parents.first(where: {$0.id == id }) else { return }
        
        modelContext.delete(target)
    }
    private func remove_child(_ id: T.C.ID) {
        guard let element = children.first(where: { $0.id == id }) else { return }
        
        modelContext.delete(element)
    }
    
    var body: some View {
        List {
            ForEach(helpers) { helper in
                Button(action: {
                    withAnimation(.spring()) {
                        helper.childrenShown.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: helper.childrenShown ? "chevron.down" : "chevron.right")
                        Text(helper.target.name)
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain).contextMenu {
                    Button(action: {
                        add_child(helper.target.id)
                    }) {
                        Label("Add \(T.kind.subName)", systemImage: "plus")
                    }
                    Button(action: {
                        selected = helper.target
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: {
                        remove_parent(helper.target.id)
                    }) {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }
                }
                
                if helper.childrenShown {
                    ForEach(helper.target.children) { child in
                        HStack {
                            Text(child.name).padding(.leading, 30)
                        }.contentShape(Rectangle()).contextMenu {
                            Button(action: {
                                selectedChild = child
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(action: {
                                remove_child(child.id)
                            }) {
                                Label("Delete", systemImage: "trash").foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
        }.contextMenu {
            Button("Add \(T.kind.rawValue)", action: add_parent)
        }.padding()
        .navigationTitle(T.kind.pluralized)
        .toolbar {
            ToolbarItemGroup {
                Button(action: add_parent) {
                    Label("Add \(T.kind.rawValue)", systemImage: "plus")
                }.help("Add a \(T.kind.rawValue)")
            }
        }
        .sheet(item: $selected, onDismiss: {
            let empty = parents.filter { $0.name.isEmpty };
            for item in empty {
                modelContext.delete(item)
            }
        }) { item in
            NamedPairParentEditor(target: item)
        }
        .sheet(item: $selectedChild, onDismiss: {
            /*
            let empty = children.filter { $0.name.isEmpty || $0.parent == nil };
            for item in empty {
                modelContext.delete(item)
            }
             */
        }) { item in
            NamedPairChildEditor(target: item)
        }
    }
}

#Preview {
    AllNamedPairViewEdit<Category>().modelContainer(Containers.previewContainer)
}
