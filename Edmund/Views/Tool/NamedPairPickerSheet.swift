//
//  NamedPickerSheet.swift
//  Edmund
//
//  Created by Hollan on 1/10/25.
//

import SwiftUI;
import SwiftData;


enum NamedPickerAction: String {
    case ok
    case cancel
}

/// Represents the view to insert in the .sheet for the NamedPairPicker
struct NamedPairPickerSheet<P> : View where P: BoundPairParent, P: PersistentModel {
    @Binding var selectedID: P.C.ID?;
    @State private var parentSelected: P.ID?;
    
    @Query private var parents: [P];
    
    var on_dismiss: ((NamedPickerAction) -> Void)
    
    var body: some View {
        VStack {
            HStack {
                Text(P.kind.rawValue)
                
                if parents.isEmpty {
                    Text("There are no elements to pick from").italic()
                }
                else {
                    Picker("", selection: $parentSelected) {
                        Text("None").tag(nil as P.ID?)
                        ForEach(parents) { parent in
                            Text(parent.name).tag(parent.id)
                        }
                    }
                    Picker("", selection: $selectedID) {
                        Text("None").tag(nil as P.C.ID?)
                        if let parentID = parentSelected, let children = parents.first( where: { $0.id == parentID} )?.children {
                            ForEach(children) { child in
                                Text(child.name).tag(child.id)
                            }
                        }
                    }
                }
            }.padding()
            HStack {
                Spacer()
                Button("Ok", action: {
                    on_dismiss(.ok)
                }).buttonStyle(.borderedProminent)
                
                Button("Cancel", action: {
                    on_dismiss(.cancel)
                })
            }.padding()
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
    NamedPairPickerSheet<Account>(selectedID: selected_bind, on_dismiss: { print("done with \($0)") } )
}
