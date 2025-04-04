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
    }
    
    var target: T
    var id: T.ID { target.id }
    var childrenShown: Bool = false
    
    var children: [T.C] {
        target.children.sorted(by: { $0.name < $1.name } )
    }
}

@Observable
class AllNamedPairsVE_MV<T> where T: BoundPairParent{
    init() {
        self.data = []
    }
    
    func refresh(_ new: [T]) {
        self.data = new.map { .init($0) }
    }
    func set_expansion(_ val: Bool) {
        for inner in data {
            inner.childrenShown = val 
        }
    }
    
    var data: [AllPairsHelper<T>];
}

struct AllNamedPairViewEdit<T> : View where T: BoundPairParent, T: PersistentModel, T.C.P == T {
    @Query private var parents: [T];
    @Query private var children: [T.C];
    
    var vm: AllNamedPairsVE_MV<T>;
    @State private var selected: T?;
    @State private var selectedChild: T.C?;
    @State private var listSelected = Set<T.ID>();
    @State private var inspectionMode: InspectionMode = .view;
    
    @Environment(\.modelContext) private var modelContext;
    
    private func remove_parent(_ id: T.ID) {
        guard let target = parents.first(where: {$0.id == id }) else { return }
        
        modelContext.delete(target)
    }
    private func remove_child(_ id: T.C.ID) {
        guard let element = children.first(where: { $0.id == id }) else { return }
        
        modelContext.delete(element)
    }
    
    var body: some View {
        List(vm.data.sorted(by: { $0.target.name < $1.target.name })) { helper in
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
                    inspectionMode = .view
                    selected = helper.target
                }) {
                    Label("Inspect", systemImage: "info.circle")
                }
                
                Button(action: {
                    inspectionMode = .edit
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
                            inspectionMode = .view
                            selectedChild = child
                        }) {
                            Label("Inspect", systemImage: "info.circle")
                        }
                        Button(action: {
                            inspectionMode = .edit
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
        }.padding()
        .navigationTitle(T.kind.pluralized)
        .sheet(item: $selected) { item in
            NamedPairParentVE(item, isEdit: inspectionMode == .edit)
        }
        .sheet(item: $selectedChild) { item in
            NamedPairChildVE(item, isEdit: inspectionMode == .edit)
        }.onAppear {
            vm.refresh(parents)
        }
    }
}

#Preview {
    AllNamedPairViewEdit<Category>(vm: .init()).modelContainer(Containers.debugContainer)
}
