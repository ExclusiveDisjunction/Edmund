//
//  AccountPicker.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI
import SwiftData

struct NamedPairPicker<T> : View where T: NamedPair {
    init(parent: String = "", child: String = "", on: [T]) {
        self.selectedID = nil
        self.names = .init(parent, child)
        self.on = on
    }
    
    @State private var selectedID: UUID?;
    @State private var names: UnboundNamedPair;
    @State private var prev_selected_hash: Int? = nil;
    
    @State private var showing_sheet: Bool = false;
    
    /// Represents the last value pulled out of `get_account`, used to speed up the retreival process.
    @State private var last_result: T? = nil;
    
    private var on: [T];

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
    private func dismiss_sheet(action: NamedPickerAction) {
        switch action {
        case .cancel:
            names = .init();
            selectedID = nil;
            prev_selected_hash = nil;
            showing_sheet = false;
            
        case .ok:
            if let sel = selectedID, let acc = on.first(where: { $0.id == sel } ) {
                self.names = .init(from: acc)
                self.prev_selected_hash = names.hashValue;
            }
            
            showing_sheet = false;
        }
    }
    
    var body: some View {
        HStack {
            NamedPairEditor(pair: $names)
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            NamedPairPickerSheet(selectedID: $selectedID, elements: on, on_dismiss: dismiss_sheet)
        }
    }
}

#Preview {
    NamedPairPicker<SubAccount>(on: []).padding()
}
