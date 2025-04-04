//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

@Observable
class PairHelper: Identifiable, Hashable, Equatable {
    init(_ parent: String, _ child: String) {
        self.parent = parent
        self.child = child
    }
    init<T>(_ target: T) where T: BoundPair {
        self.parent = target.parent_name ?? ""
        self.child = target.name
    }
    
    var parent: String;
    var child: String;
    var id: UUID = UUID();
    
    func clear() {
        self.parent = ""
        self.child = ""
    }
    
    static func == (lhs: PairHelper, rhs: PairHelper) -> Bool {
        lhs.parent == rhs.parent && lhs.child == rhs.child
    }
    static func ==<T>(lhs: PairHelper, rhs: T) -> Bool where T: BoundPair {
        lhs.parent == rhs.parent_name && lhs.child == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(parent)
        hasher.combine(child)
    }
}

struct PairEditor : View {
    @Bindable var pair: PairHelper;
    var kind: NamedPairKind;
    
    var body: some View {
        HStack {
            TextField(kind.rawValue, text: $pair.parent)
            TextField(kind.subNamePlural, text: $pair.child)
        }
    }
}

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
            Picker(C.kind.rawValue, selection: $selectedParent) {
                Text("None").tag(nil as C.P?)
                ForEach(parents, id: \.id) { parent in
                    Text(parent.name).tag(parent as C.P?)
                }
            }.labelsHidden()
            
            Picker(C.kind.subName, selection: $target) {
                Text("None").tag(nil as C?)
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
