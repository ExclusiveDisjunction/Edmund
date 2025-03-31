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
    init(target: Binding<C?>, parent_default: String = "", child_default: String = "") {
        self._target = target;
        self.working = .init(parent_default, child_default)
    }
    
    @Binding var target: C?;
    @State private var showing_sheet: Bool = false;
    
    @State private var working: PairHelper;
    
    @State private var selectedID: C.ID?;
    @State private var prev_selected_hash: Int?;
    
    @Query private var on: [C.P];
    @Query var all_children: [C];
    
    func get_account() {
        //First we check to see the previous result
        if let res = target {
            if working == res && res.id == selectedID {
                return
            }
        }
        
        if let sel = selectedID {
            if working.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                target = all_children.first(where: { $0.id == sel })
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        target = all_children.first(where: { working == $0 } )
    }
    func clear() {
        working.clear()
        selectedID = nil
        prev_selected_hash = nil
    }
    
    func resolve_on_selected() {
        if let id = self.selectedID, let acc = all_children.first(where: {$0.id == id } ) {
            self.working = .init(acc)
            self.prev_selected_hash = self.working.hashValue
            self.target = acc
        } else {
            clear()
        }
    }
    
    private func dismiss_sheet(action: NamedPickerAction) {
        switch action {
        case .cancel:
            clear()
        case .ok:
            resolve_on_selected()
        }
        
        showing_sheet = false;
    }
    
    var body: some View {
        HStack {
            PairEditor(pair: working, kind: C.kind).onSubmit {
                get_account()
            }
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            NamedPairPickerSheet<C>(selectedID: $selectedID, on_dismiss: { action in
                dismiss_sheet(action: action)
            })
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
    
    NamedPairPicker(target: bind).padding()
}
