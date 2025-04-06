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

struct AllNamedPairViewEdit<T> : View where T: BoundPairParent, T: PersistentModel, T.C.P == T {
    @Query private var parents: [T];
    @Query private var children: [T.C];
    
    var vm: AllNamedPairsVE_MV<T>;
    @State private var parentInspect: InspectionManifest<T>?;
    @State private var childInspect: InspectionManifest<T.C>?;
    @State private var selectedParents: Set<T.ID> = [];
    @State private var deleting: DeletingAction<T>? = nil
    @State private var deletingChild: DeletingAction<T.C>? = nil;
    @State private var isDeleting: Bool = false;
    @State private var isDeletingChild: Bool = false;
    
    @Environment(\.modelContext) private var modelContext;
    
    private func add_parent() {
        
    }
    private func add_child() {
        
    }
    
    private func parents_remove_from(_ offsets: IndexSet) {
        let targets = offsets.map { vm.data[$0].target }
        if !targets.isEmpty {
            deleting = .init(data: targets)
            isDeleting = true
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
                GeneralContextMenu(child, inspect: $childInspect, remove: $deletingChild, isDeleting: $isDeletingChild)
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
                GeneralContextMenu(helper.target, inspect: $parentInspect, remove: $deleting, isDeleting: $isDeleting, addLabel: T.kind.addSubName, add: add_parent)
            }
            
            if helper.childrenShown {
                childrenList(parent: helper.target)
            }
        }.padding()
        .sheet(item: $parentInspect) { inspect in
            NamedPairParentVE(inspect.value, isEdit: inspect.mode == .edit)
        }
        .sheet(item: $childInspect) { inspect in
            NamedPairChildVE(inspect.value, isEdit: inspect.mode == .edit)
        }.confirmationDialog("Removing this information will remove all associated transactions. Do you wish to continue?", isPresented: $isDeleting, titleVisibility: .visible) {
            DeletingActionConfirm(isPresented: $isDeleting, action: $deleting)
        }.confirmationDialog("Removing this information will remove all associated transactions. Do you wish to continue?", isPresented: $isDeletingChild, titleVisibility: .visible) {
            DeletingActionConfirm(isPresented: $isDeleting, action: $deleting)
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
