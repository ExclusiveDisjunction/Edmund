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

struct NamedPairPicker<C> : View where C: BoundPair, C: PersistentModel {
    init(target: Binding<C.ID?>, parent_default: String = "", child_default: String = "") {
        self._target = target;
        //self.working = .init(parent_default, child_default)
    }
    
    @Binding var target: C.ID?;
    @Query private var parents: [C.P];
    //@Query var children: [C];
    
    @State private var selectedParentID: C.P.ID?;
    @State private var selectedChildID: C.ID?;
    
    var body: some View {
        HStack {
            Picker(C.kind.rawValue, selection: $selectedParentID) {
                Text("None").tag(nil as C.P.ID?)
                ForEach(parents) { parent in
                    Text(parent.name).tag(parent.id)
                }
            }.labelsHidden()
            
            Picker(C.kind.subName, selection: $selectedChildID) {
                Text("None").tag(nil as C.ID?)
                if let parentID = selectedParentID, let parent = parents.first(where: {$0.id == parentID } ) {
                    ForEach(parent.children) { child in
                        Text(child.name).tag(child.id)
                    }
                }
            }.labelsHidden()
        }
    }
}

#Preview {
    var pair: SubCategory.ID? = nil;
    let bind = Binding<SubCategory.ID?>(
        get: {
            pair
        },
        set: {
            pair = $0
        }
    );
    
    NamedPairPicker<SubCategory>(target: bind).padding().modelContainer(ModelController.previewContainer)
}
