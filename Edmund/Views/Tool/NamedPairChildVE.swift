//
//  NamedPairChildEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI
import SwiftData

@Observable
class NamedPairChildManifest<C> : Identifiable, Hashable, Equatable where C: BoundPair {
    init(_ from: C) {
        self.name = from.name
        self.parent = from.parent
        self.id = UUID()
    }
    
    var id: UUID;
    var name: String;
    var parent: C.P?;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    static func ==(_ lhs: NamedPairChildManifest<C>, _ rhs: NamedPairChildManifest<C>)  -> Bool{
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
}

struct NamedPairChildVE<C> : View where C: BoundPair, C.P: PersistentModel {
    init(_ target: C, isEdit: Bool = false) {
        self.target = target
        
        let tmpManifest = NamedPairChildManifest(target);
        self.editManifest = isEdit ? tmpManifest : nil;
        self.editHash = isEdit ? tmpManifest.hashValue : 0;
    }
    
    @Bindable var target: C
    
    @State private var editManifest: NamedPairChildManifest<C>?;
    @State private var askSwitch = false;
    @State private var editHash: Int;
    @State private var show_red_parent = false;
    @State private var show_red = false;
    @State private var show_alert = false;
    
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.modelContext) private var modelContext;
    
#if os(macOS)
    let labelMinWidth: CGFloat = 50;
    let labelMaxWidth: CGFloat = 60;
#else
    let labelMinWidth: CGFloat = 80;
    let labelMaxWidth: CGFloat = 85;
#endif

    @Query private var parents: [C.P];
    
    private func saveChanges() -> Bool {
        guard self.validate() else { return false }
        guard let edit = self.editManifest else { return true }
        
        self.target.name = edit.name
        self.target.parent = edit.parent
        
        return true 
    }
    private func validate() -> Bool {
        guard let edit = self.editManifest else { return true }
        
        show_red = edit.name.isEmpty;
        show_red_parent = edit.parent == nil;
        show_alert = show_red || show_red_parent;
        
        return !show_alert
    }
    private func submit() {
        if saveChanges() {
            dismiss()
        }
    }
    private func toggleEdit() {
        if validate() {
            if editManifest == nil {
                editManifest = .init(target)
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
    
    var body: some View {
        VStack {
            Text(target.name.isEmpty ? "No Name" : target.name).font(.title2)
            Button(action: toggleEdit) {
                Image(systemName: editManifest != nil ? "info.circle" : "pencil").resizable()
            }.buttonStyle(.borderless)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(.accent)
                .padding(.trailing)

            Grid {
                GridRow {
                    Text(C.kind.name).frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    
                    if let edit = editManifest {
                        Picker(C.kind.name, selection: Binding(get: { edit.parent }, set: { edit.parent = $0 })) {
                            Text("None").tag(nil as C.P?)
                            ForEach(parents, id: \.id) { parent in
                                Text(parent.name).tag(parent as C.P?)
                            }
                        }.foregroundStyle(show_red_parent ? Color.red : Color.primary).labelsHidden()
                    }
                    else {
                        HStack {
                            Text(target.parent?.name ?? "No \(C.kind.rawValue)")
                            Spacer()
                        }
                    }
                }
                GridRow {
                    Text("Name").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
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
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok", action: submit ).buttonStyle(.borderedProminent)
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
        }.confirmationDialog("There are unsaved changes.", isPresented: $askSwitch) {
            Button("Save Changes", action: {
                if saveChanges() {
                    editManifest = nil
                    editHash = 0
                }
                askSwitch = false
            })
        }
    }
}

#Preview {
    let child = Account.exampleAccounts[0].children[0]
    
    NamedPairChildVE(child).modelContainer(Containers.debugContainer)
}
