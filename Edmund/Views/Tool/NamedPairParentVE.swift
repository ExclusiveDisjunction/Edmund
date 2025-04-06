//
//  NamedPairParentEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI

@Observable
class ParentEditManifest : Identifiable, Hashable, Equatable {
    init(_ name: String) {
        self.id = UUID()
        self.name = name
    }
    
    var id: UUID;
    var name: String;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name);
    }
    static func == (lhs: ParentEditManifest, rhs: ParentEditManifest) -> Bool {
        lhs.name == rhs.name
    }
}

struct NamedPairParentVE<P> : View where P : BoundPairParent {
    @Bindable var target: P;
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    @State private var show_red = false;
    @State private var show_alert = false;
    
    @State private var editManifest: ParentEditManifest?;
    @State private var askSwitch = false;
    @State private var editHash: Int;
    
    init(_ target: P, isEdit: Bool = false) {
        self.target = target
        
        let tmpManifest = ParentEditManifest(target.name)
        self.editManifest = isEdit ? tmpManifest : nil
        self.editHash = isEdit ? tmpManifest.hashValue : 0
    }
    
    private func validate() -> Bool {
        guard let edit = self.editManifest else { return true }
        
        if edit.name.isEmpty {
            show_red = true;
            show_alert = true;
            
            return false
        }
        else {
            return true
        }
    }
    private func submit() {
        if validate() {
            if let edit = editManifest {
                target.name = edit.name
            }
            
            dismiss()
        }
    }
    private func toggleEdit() {
        if validate() {
            if editManifest == nil {
                editManifest = .init(target.name)
                editHash = editManifest!.hashValue
            }
            else {
                if editHash != editManifest!.hashValue {
                    askSwitch = true
                }
                else {
                    editHash = 0
                    editManifest = nil
                }
            }
        }
    }
    
    var body : some View {
        VStack {
            Text(target.name.isEmpty ? "No Name" : target.name).font(.title2)
            Button(action: toggleEdit) {
                Image(systemName: editManifest != nil ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.accent)
                .padding(.trailing)
            
            HStack {
                Text("Name")
                if let edit = editManifest {
                    TextField("Name", text: Binding(get: { edit.name }, set: { edit.name = $0 })).foregroundStyle(show_red ? Color.red : Color.primary).onSubmit(submit).labelsHidden().textFieldStyle(.roundedBorder)
                }
                else {
                    HStack {
                        Text(target.name)
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button(editManifest == nil ? "Ok" : "Save", action: submit ).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false;
            })
        }, message: {
            Text("Please provide a name.")
        }).onDisappear {
            if target.name.isEmpty {
                modelContext.delete(target)
            }
        }.confirmationDialog("There are unsaved changes.", isPresented: $askSwitch) {
            Button("Save", action: {
                target.name = editManifest?.name ?? target.name
                editManifest = nil
                editHash = 0
                askSwitch = false
            })
            
            Button("Discard Changes") {
                editManifest = nil
                editHash = 0
                askSwitch = false
            }
            
            Button("Cancel", role: .cancel) {
                askSwitch = false
            }
        }
    }
}

#Preview {
    let parent = Category.exampleCategories[0];
    
    NamedPairParentVE(parent)
}
