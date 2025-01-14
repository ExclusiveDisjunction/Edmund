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
    
    private var on: [T];

    func get_account() -> T? {
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                return on.first(where: { $0.id == sel })
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        return on.first(where: { $0.eqByName(names) } )
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
