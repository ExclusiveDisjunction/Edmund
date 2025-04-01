//
//  NamedPairChildEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI
import SwiftData

struct NamedPairChildEditor<C> : View where C: BoundPair, C.P: PersistentModel {
    @Bindable var target: C
    @State private var show_red_parent = false;
    @State private var show_red = false;
    @State private var show_alert = false;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;

    @Query private var parents: [C.P];
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Picker(C.kind.rawValue, selection: $target.parent) {
                        Text("None").tag(nil as C.P?)
                        ForEach(parents, id: \.id) { parent in
                            Text(parent.name).tag(parent as C.P?)
                        }
                    }.foregroundStyle(show_red_parent ? Color.red : Color.primary)
                    
                    TextField("Name", text: $target.name).foregroundStyle(show_red ? Color.red : Color.primary)
                }
            }
            
            HStack {
                Spacer()
                Button("Ok", action: {
                    show_red_parent = target.parent == nil
                    show_red = target.name.isEmpty
                    
                    show_alert = show_red_parent || show_red
                    if !show_alert {
                        dismiss()
                    }
                }).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false
            })
        }, message: {
            Text("Please ensure that there is a \(C.kind.rawValue), and a name.")
        }).onDisappear {
            if target.name.isEmpty || target.parent == nil {
                modelContext.delete(target)
            }
        }
    }
}

#Preview {
    let child = Account.exampleAccounts[0].children[0]
    
    NamedPairChildEditor(target: child).modelContainer(ModelController.previewContainer)
}
