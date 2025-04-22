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
class AllNamedPairsVE_MV<T> where T: BoundPairParent, T: PersistentModel{
    init() {
        self.data = []
    }
    
    func refresh(context: ModelContext) {
        let data = ( try? context.fetch(FetchDescriptor<T>()) ) ?? [];
        
        self.refresh(data)
    }
    func refresh(_ new: [T]) {
        self.data = new.sorted(by: { $0.name < $1.name } ).map { .init($0) }
    }
    func set_expansion(_ val: Bool) {
        for inner in data {
            inner.childrenShown = val 
        }
    }
    
    var data: [AllPairsHelper<T>];
}

struct AllNamedPairViewEdit<T> : View where T: BoundPairParent, T: PersistentModel, T.C.P == T, T: EditableElement, T.C: EditableElement {
    @Query private var parents: [T];
    @Query private var children: [T.C];
    
    var vm: AllNamedPairsVE_MV<T>;
    @State private var selectedParents: Set<T.ID> = [];
    
    @Bindable private var parentEdit: InspectionManifest<T> = .init();
    @Bindable private var childInspect: InspectionManifest<T.C> = .init();
    @Bindable private var warning: WarningManifest = .init();
    @Bindable private var parentDelete: DeletingManifest<T> = .init();
    @Bindable private var childDelete: DeletingManifest<T.C> = .init();
    
    @Environment(\.modelContext) private var modelContext;
    
    private func add_parent() {
        parentEdit.open(.init(), mode: .edit)
    }
    private func add_child() {
        childInspect.open(.init(), mode: .edit)
    }
    
    private func parents_remove_from(_ offsets: IndexSet) {
        let targets = offsets.map { vm.data[$0].target }
        if !targets.isEmpty {
            parentDelete.action = targets
        }
    }
    private func refresh() {
        self.vm.refresh(context: modelContext)
    }
    
    @ViewBuilder
    func childrenList(parent: T) -> some View {
        ForEach(parent.children) { child in
            HStack {
                Text(child.name).padding(.leading, 30)
            }.contentShape(Rectangle()).contextMenu {
                GeneralContextMenu(child, inspect: childInspect, remove: childDelete, canInspect: false)
            }
        }
    }
    
    var body: some View {
        List(vm.data) { helper in
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
                GeneralContextMenu(helper.target, inspect: parentEdit, remove: parentDelete, addLabel: T.kind.addSubName, add: add_parent, canInspect: false)
            }
            
            if helper.childrenShown {
                childrenList(parent: helper.target)
            }
        }.padding()
            .sheet(item: $parentEdit.value) { target in
                ElementEditor(target)
            }
            .sheet(item: $childInspect.value) { target in
                ElementEditor(target)
            }.confirmationDialog("Removing this information will remove all associated transactions. Do you wish to continue?", isPresented: $parentDelete.isDeleting, titleVisibility: .visible) {
                DeletingActionConfirm(parentDelete)
            }.confirmationDialog("Removing this information will remove all associated transactions. Do you wish to continue?", isPresented: $childDelete.isDeleting, titleVisibility: .visible) {
                DeletingActionConfirm(childDelete)
            }
    }
}

#Preview {
    let container = Containers.debugContainer
    let vm = AllNamedPairsVE_MV<Category>();
    
    NavigationStack {
        AllNamedPairViewEdit<Category>(vm: vm).modelContainer(container).onAppear {
            vm.refresh(context: container.mainContext)
        }
    }
}
