//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

@Observable
class NamedPickerVM<T> where T: NamedPair {
    init(parent: String = "", child: String = "") {
        self.names = .init(parent, child)
        self.selectedID = nil
        self.prev_selected_hash = nil
        self.last_result = nil
    }
    
    var selectedID: UUID?;
    var names: UnboundNamedPair;
    var prev_selected_hash: Int?;
    
    var last_result: T?;
    @Query var on: [T];
    
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

struct NamedPairPicker<T> : View where T: NamedPair {
    @Bindable var vm: NamedPickerVM<T>;
    @State private var showing_sheet: Bool = false;
    
    private func dismiss_sheet(action: NamedPickerAction) {
        switch action {
        case .cancel:
            vm.clear()
        case .ok:
            vm.resolve_on_selected()
        }
        
        showing_sheet = false;
    }
    
    var body: some View {
        HStack {
            NamedPairEditor(pair: $vm.names)
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            NamedPairPickerSheet(selectedID: $vm.selectedID, elements: vm.on, on_dismiss: dismiss_sheet)
        }
    }
}

#Preview {
    NamedPairPicker<SubAccount>(vm: .init(on: [])).padding()
}
