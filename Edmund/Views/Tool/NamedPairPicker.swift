//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

/*
@Observable
class NamedPickerVM<T> where T: NamedPair {
    init(parent: String = "", child: String = "", on: [T]) {
        self.names = .init(parent, child)
        self.selectedID = nil
        self.prev_selected_hash = nil
        self.last_result = nil
        self.on = on
    }
    
    var selectedID: UUID?;
    var names: UnboundNamedPair;
    var prev_selected_hash: Int?;
    
    var last_result: T?;
    var on: [T];
    
    func get_account() -> T? {
        //First we check to see the previous result
        if let res = last_result {
            if res.eqByName(names) && res.id == selectedID {
                return res
            }
        }
        
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                last_result = on.first(where: { $0.id == sel })
                return last_result
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        last_result = on.first(where: { $0.eqByName(names) } )
        return last_result
    }
    func clear() {
        names = .init()
        selectedID = nil
        prev_selected_hash = nil
    }
    
    func resolve_on_selected() {
        if let id = self.selectedID, let acc = on.first(where: {$0.id == id } ) {
            self.names = .init(from: acc)
            self.prev_selected_hash = names.hashValue
        } else {
            clear()
        }
    }
}
 */

struct NamedPairPicker<T> : View where T: NamedPair, T: PersistentModel {
    init(target: Binding<T?>, parent_default: String = "", child_default: String = "") {
        self.target = target;
        self.names = .init(parent_default, child_default)
    }
    
    @State var target: Binding<T?>
    @State private var showing_sheet: Bool = false;
    @State private var names: UnboundNamedPair
    @State private var selectedID: UUID?;
    @State private var prev_selected_hash: Int?;
    
    @Query private var on: [T];
    
    func get_account() {
        //First we check to see the previous result
        if let res = target.wrappedValue {
            if res.eqByName(names) && res.id == selectedID {
                //do nothing, we have our result
                return
            }
        }
        
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                target.wrappedValue = on.first(where: { $0.id == sel })
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        target.wrappedValue = on.first(where: { $0.eqByName(names) } )
    }
    func clear() {
        names = .init()
        selectedID = nil
        prev_selected_hash = nil
    }
    
    func resolve_on_selected() {
        if let id = self.selectedID, let acc = on.first(where: {$0.id == id } ) {
            self.names = .init(from: acc)
            self.prev_selected_hash = names.hashValue
            self.target.wrappedValue = acc
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
            NamedPairEditor(pair: $names).onSubmit {
                get_account()
            }
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            NamedPairPickerSheet(selectedID: $selectedID, elements: on, on_dismiss: { action in
                dismiss_sheet(action: action)
            })
        }
    }
}

#Preview {
    var pair: SubAccount? = nil;
    let bind = Binding<SubAccount?>(
        get: {
            pair
        },
        set: {
            pair = $0
        }
    );
    
    NamedPairPicker<SubAccount>(target: bind).padding()
}
