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

struct NamedPairChildEdit<C> : View where C: BoundPair, C.P: PersistentModel {
    init(_ target: C) {
        self.target = target
        
        let tmpManifest = NamedPairChildManifest(target);
        self.editManifest = tmpManifest;
        self.editHash = tmpManifest.hashValue;
    }
    
    @Bindable var target: C
    
    @State private var editManifest: NamedPairChildManifest<C>;
    @State private var editHash: Int;
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
        
        self.target.name = editManifest.name
        self.target.parent = editManifest.parent
        
        return true 
    }
    private func validate() -> Bool {
        show_alert = editManifest.name.isEmpty || editManifest.parent == nil
        
        return !show_alert
    }
    private func submit() {
        if saveChanges() {
            dismiss()
        }
    }
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text(C.kind.name).frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    Picker(C.kind.name, selection: $editManifest.parent) {
                        Text("None").tag(nil as C.P?)
                        ForEach(parents, id: \.id) { parent in
                            Text(parent.name).tag(parent as C.P?)
                        }
                    }.labelsHidden()
                }
                GridRow {
                    Text("Name").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                    TextField("Name", text: $editManifest.name).onSubmit(submit).labelsHidden().textFieldStyle(.roundedBorder)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel", action: { dismiss() } ).buttonStyle(.bordered)
                Button("Ok", action: submit ).buttonStyle(.borderedProminent)
            }
        }.padding().alert("Error", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false
            })
        }, message: {
            Text("Please fill in all fields")
        }).onDisappear {
            if !validate() {
                modelContext.delete(target)
            }
        }
    }
}

#Preview {
    let child = Account.exampleAccounts[0].children[0]
    
    NamedPairChildEdit(child).modelContainer(Containers.debugContainer)
}
