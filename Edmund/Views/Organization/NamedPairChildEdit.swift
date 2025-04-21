//
//  NamedPairChildEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI
import SwiftData

@Observable
final class NamedPairChildSnapshot<C> : ElementSnapshot where C: BoundPair, C: EditableElement {
    
    init(_ from: C) {
        self.name = from.name
        self.parent = from.parent
        self.id = UUID()
    }
    
    var id: UUID;
    var name: String;
    var parent: C.P?;
    
    func validate() -> Bool {
        !name.isEmpty && parent != nil;
    }
    func apply(_ to: C, context: ModelContext) {
        to.name = name;
        to.parent = parent;
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    static func ==(_ lhs: NamedPairChildSnapshot<C>, _ rhs: NamedPairChildSnapshot<C>)  -> Bool{
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
}

struct NamedPairChildEdit<C> : ElementEditView where C: BoundPair, C.P: PersistentModel, C: EditableElement, C.Snapshot == NamedPairChildSnapshot<C> {
    init(_ data: C.Snapshot) {
        self.snapshot = data
    }
    
    typealias For = C;
    
    @State private var snapshot: NamedPairChildSnapshot<C>;
    
#if os(macOS)
    let labelMinWidth: CGFloat = 50;
    let labelMaxWidth: CGFloat = 60;
#else
    let labelMinWidth: CGFloat = 80;
    let labelMaxWidth: CGFloat = 85;
#endif

    @Query private var parents: [C.P];
    
    var body: some View {
        Grid {
            GridRow {
                Text(C.kind.name).frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                Picker(C.kind.name, selection: $snapshot.parent) {
                    Text("None").tag(nil as C.P?)
                    ForEach(parents, id: \.id) { parent in
                        Text(parent.name).tag(parent as C.P?)
                    }
                }.labelsHidden()
            }
            GridRow {
                Text("Name").frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                TextField("Name", text: $snapshot.name).labelsHidden().textFieldStyle(.roundedBorder)
            }
        }
    }
}

#Preview {
    let child = Account.exampleAccounts[0].children[0]
    
    ElementEditor(child).modelContainer(Containers.debugContainer)
}
