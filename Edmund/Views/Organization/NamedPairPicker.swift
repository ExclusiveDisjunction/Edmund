//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

struct NamedPairPicker<C> : View where C: BoundPair, C: PersistentModel, C.P.C == C {
    init(_ target: Binding<C?>) {
        selectedParent = target.wrappedValue?.parent
        _target = target
    }
    
    @Binding var target: C?;
    @State private var selectedParent: C.P?;
    @Query private var parents: [C.P];
    
    var body: some View {
        HStack {
            Picker(C.kind.name, selection: $selectedParent) {
                Text(C.kind.name).tag(nil as C.P?)
                ForEach(parents, id: \.id) { parent in
                    Text(parent.name).tag(parent as C.P?)
                }
            }.labelsHidden()
            
            Picker(C.kind.subName, selection: $target) {
                Text(C.kind.subName).tag(nil as C?)
                if let parent = selectedParent {
                    ForEach(parent.children, id: \.id) { child in
                        Text(child.name).tag(child as C?)
                    }
                }
            }.labelsHidden()
        }
    }
}

#Preview {
    var pair: SubCategory? = SubCategory.exampleSubCategory;
    let bind = Binding<SubCategory?>(
        get: {
            pair
        },
        set: {
            pair = $0
        }
    );
    
    NamedPairPicker(bind).padding().modelContainer(Containers.debugContainer)
}
