//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

/// Allows for the dynamic selection of a named pair child (and by proxy, parent) from the `ModelContext`'s store of bound pairs, over type `C` and `C.P`. 
public struct NamedPairPicker<C> : View where C: BoundPair, C: TypeTitled, C: PersistentModel, C.P.C == C, C.P: TypeTitled {
    public init(_ target: Binding<C?>) {
        if let child = target.wrappedValue {
            _selectedParent = .init(initialValue: child.parent)
        }
        _target = target
    }
    
    @Binding private var target: C?;
    @State private var selectedParent: C.P?;
    @Query private var parents: [C.P];
    
    public var body: some View {
        HStack {
            Picker("", selection: $selectedParent) {
                Text(C.P.typeDisplay.singular)
                    .tag(nil as C.P?)
                
                ForEach(parents, id: \.id) { parent in
                    Text(parent.name)
                        .tag(parent as C.P?)
                }
            }.labelsHidden()
            
            Picker("", selection: $target) {
                Text(C.typeDisplay.singular)
                    .tag(nil as C?)
                
                if let parent = selectedParent {
                    ForEach(parent.children, id: \.id) { child in
                        Text(child.name)
                            .tag(child as C?)
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
