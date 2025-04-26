//
//  NamedPairChildEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI
import SwiftData

@Observable
public final class NamedPairChildSnapshot<C> : ElementSnapshot where C: BoundPair, C: EditableElement {
    public init(_ from: C) {
        self.name = from.name
        self.parent = from.parent
        self.id = UUID()
    }
    
    public var id: UUID;
    public var name: String;
    public var parent: C.P?;
    
    public func validate() -> Bool {
        !name.isEmpty && parent != nil;
    }
    public func apply(_ to: C, context: ModelContext) {
        to.name = name;
        to.parent = parent;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(parent)
    }
    public static func ==(_ lhs: NamedPairChildSnapshot<C>, _ rhs: NamedPairChildSnapshot<C>)  -> Bool{
        lhs.name == rhs.name && lhs.parent == rhs.parent
    }
}

public struct NamedPairChildEdit<C> : ElementEditorView where C: BoundPair, C.P: PersistentModel, C: EditableElement, C.Snapshot == NamedPairChildSnapshot<C> {
    public init(_ data: C.Snapshot) {
        self.snapshot = data
    }
    
    public typealias For = C;
    
    @State private var snapshot: NamedPairChildSnapshot<C>;
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 50;
    private let labelMaxWidth: CGFloat = 60;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 85;
#endif

    @Query private var parents: [C.P];
    
    public var body: some View {
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
    let child = Account.exampleAccounts[0].children![0]
    
    ElementEditor(child).modelContainer(Containers.debugContainer)
}
