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
    struct ParentPicker : View {
        @Binding var target: C.P?;
        
        @Query private var parents: [C.P];
        
        var body: some View {
            Picker(C.kind.rawValue, selection: $target) {
                Text("None").tag(nil as C.P?)
                ForEach(parents) { parent in
                    Text(parent.name).tag(parent.id)
                }
            }.labelsHidden()
        }
    }
    
    struct ChildPicker : View  {
        @Binding var target: C?;
        @Binding var parent: C.P?;
        
        var body: some View {
            Picker(C.kind.subName, selection: $target) {
                Text("None").tag(nil as C?)
                if let parent = parent {
                    ForEach(parent.children, id: \.self) { child in
                        Text(child.name).tag(child as C?)
                    }
                }
            }.labelsHidden()
        }
    }
    
    init(target: Binding<C?>) {
        self._target = target;
        //self.working = .init(parent_default, child_default)
    }
    
    @Binding var target: C?;
    @Query private var parents: [C.P];
    //@Query var children: [C];
    
    @State private var selectedParent: C.P?;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    var body: some View {
        if horizontalSizeClass == .compact {
            VStack {
                ParentPicker(target: $selectedParent)
                ChildPicker(target: $target, parent: $selectedParent)
            }
        }
        else {
            HStack {
                ParentPicker(target: $selectedParent)
                ChildPicker(target: $target, parent: $selectedParent)
            }
        }
    }
}

#Preview {
    var pair: SubCategory? = nil;
    let bind = Binding<SubCategory?>(
        get: {
            pair
        },
        set: {
            pair = $0
        }
    );
    
    NamedPairPicker(target: bind).padding().modelContainer(ModelController.previewContainer)
}
