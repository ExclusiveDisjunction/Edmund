//
//  NamedPickerSheet.swift
//  Edmund
//
//  Created by Hollan on 1/10/25.
//

import SwiftUI;
import SwiftData;

enum NamedPairPickerMode {
    case account
    case category
}

struct PickerSheet : View {
    @Binding var selectedID: UUID?;
    @State var mode: NamedPairPickerMode;
    @State var elements: Dictionary<UUID, NamedPair>;
    
    var body: some View {
        switch mode {
        case .account:
            Text("Account")
        case .category:
            Text("Category")
        }
        
        if elements.isEmpty {
            Text("There are no elements to pick from").italic()
        }
        else {
            Picker("", selection: $selectedID) {
                Text("None").tag(nil as UUID?)
                ForEach(elements) { (pair: (UUID, NamedPair)) in
                    NamedPairViewer(pair: pair.1).tag(pair.0 as UUID?)
                }
            }
        }
    }
}

#Preview {
    var selected: UUID? = nil;

    let selected_bind = Binding<UUID?>(
        get: {
            selected
        },
        set: {
            selected = $0
        }
    )
    
    if let selected = selected {
        Text("Selected: \(selected.uuidString)")
    }
    else {
        Text("None Selected")
    }
    PickerSheet(selectedID: selected_bind, mode: .account)
}
