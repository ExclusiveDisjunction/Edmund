//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public enum NamedPairPickerStyle {
    case horizontal, vertical
}

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
    private var style: NamedPairPickerStyle = .horizontal;
    
    @ViewBuilder
    private var parentPicker: some View {
        Picker("", selection: $selectedParent) {
            Text(C.P.typeDisplay.singular)
                .tag(nil as C.P?)
            
            ForEach(parents, id: \.id) { parent in
                Text(parent.name)
                    .tag(parent as C.P?)
            }
        }.labelsHidden()
    }
    
    @ViewBuilder
    private var childPicker: some View {
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
    
    public func namedPairPickerStyle(_ style: NamedPairPickerStyle) -> some View {
        var result = self
        result.style = style
        return result
    }
    
    public var body: some View {
        if style == .vertical {
            VStack {
                parentPicker
                childPicker
            }
        }
        else {
            HStack {
                parentPicker
                childPicker
            }
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
    
    DebugContainerView {
        NamedPairPicker(bind)
            .padding()
    }
}
