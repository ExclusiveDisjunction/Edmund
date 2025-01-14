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
enum NamedPickerAction: String {
    case ok
    case cancel
}

struct PickerSheet : View {
    @Binding var selectedID: UUID?;
    @State var mode: NamedPairPickerMode;
    @State var elements: [NamedPair];
    var on_dismiss: ((NamedPickerAction) -> Void)
    
    var body: some View {
        VStack {
            HStack {
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
    let elements: [NamedPair] = [
        .init("Checking", "Pay", id: UUID()),
        .init("Checking", "DI", id: UUID()),
        .init("Checking", "Hold", id: UUID()),
        .init("Savings", "Main", id: UUID()),
        .init("Savings", "Hold", id: UUID())
    ]
    
    if let selected = selected {
        Text("Selected: \(selected.uuidString)")
    }
    else {
        Text("None Selected")
    }
    PickerSheet(selectedID: selected_bind, mode: .account, elements: elements, on_dismiss: { print("done with \($0)") } )
}
