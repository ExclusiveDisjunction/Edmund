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
    @State private var parentID: C.P.ID?;
    @Environment(\.dismiss) private var dismiss;
    @State private var wasOk = false;

    @Query private var parents: [C.P];
    
    init(target: C) {
        self.target = target
        self.parentID = target.parent?.id
    }
    
    private func onOk() {
        if target.name.isEmpty {
            show_red = true
        }
        if let id = parentID, let oldParent = target.parent?.id {
            if id != oldParent {
                if let parent = parents.first(where: {$0.id == id}) {
                    target.parent = parent
                }
                else {
                    show_red_parent = true
                }
            }
        }
        else {
            show_red_parent = true
        }
        
        if !show_red_parent && !show_red {
            wasOk = true;
            dismiss()
        }
        else {
            show_alert = true
        }
    }
    
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text(C.kind.rawValue)
                    Picker("Parent", selection: $parentID) {
                        Text("None").tag(nil as C.P.ID?)
                        ForEach(parents, id: \.id) { parent in
                            Text(parent.name).tag(parent.id)
                        }
                    }.labelsHidden().border(show_red_parent ? Color.red : Color.clear)
                }
                
                GridRow {
                    Text("Name")
                    TextField("Name", text: $target.name).labelsHidden().border(show_red ? Color.red : Color.clear)
                }
            }
            
            HStack {
                Spacer()
                Button("Ok", action: onOk).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false
            })
        }, message: {
            Text("Please ensure that there is a \(C.kind.rawValue), and a name.")
        })
    }
}

#Preview {
    let child = Account.exampleAccounts[0].children[0]
    
    NamedPairChildEditor(target: child).modelContainer(ModelController.previewContainer)
}
