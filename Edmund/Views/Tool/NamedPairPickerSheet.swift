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
struct NamedPairPickerSheet<T> : View where T: NamedPair{
    @Binding var selectedID: UUID?;
    @State var elements: [T];
    
    var on_dismiss: ((NamedPickerAction) -> Void)
    
    var body: some View {
        VStack {
            HStack {
                switch T.kind {
                case .account:
                    Text("Account")
                case .category:
                    Text("Category")
                case .nondetermined:
                    Text("Label")
                }
                
                if elements.isEmpty {
                    Text("There are no elements to pick from").italic()
                }
                else {
                    Picker("", selection: $selectedID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(elements) { pair in
                            NamedPairViewer(pair: pair).tag(pair.id)
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
    let elements: [UnboundNamedPair] = [
        .init("Checking", "Pay"),
        .init("Checking", "DI"),
        .init("Checking", "Hold"),
        .init("Savings", "Main"),
        .init("Savings", "Hold")
    ]
    
    if let selected = selected {
        Text("Selected: \(selected.uuidString)")
    }
    else {
        Text("None Selected")
    }
    NamedPairPickerSheet(selectedID: selected_bind, elements: elements, on_dismiss: { print("done with \($0)") } )
}
