//
//  NamedPairChildEditor.swift
//  Edmund
//
//  Created by Hollan on 3/28/25.
//

import SwiftUI
import SwiftData

public struct BoundPairChildEdit<T> : ElementEditorView where T: BoundPair, T.Snapshot: BoundPairSnapshot {
    public typealias For = T;
    
    public init(_ data: T.Snapshot) {
        self.snapshot = data;
    }
    
    @Bindable private var snapshot: T.Snapshot;
    @Query private var parents: [T.P];
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 50;
    private let labelMaxWidth: CGFloat = 60;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 85;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Parent")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                Picker("", selection: $snapshot.parent) {
                    Text("None")
                        .tag(nil as T.P?)
                    
                    ForEach(parents, id: \.id) { parent in
                        Text(parent.name)
                            .tag(parent as T.P?)
                    }
                }.labelsHidden()
            }
            GridRow {
                Text("Name")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                TextField("Name", text: $snapshot.name)
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

#Preview {
    let child = Account.exampleAccounts[0].children![0]
    
    ElementEditor(child, adding: false).modelContainer(Containers.debugContainer)
}
