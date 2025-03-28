//
//  NamedPair.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI;

struct NamedPairViewer<T>: View where T: BoundPair {
    @State var pair: T;
    
    var body: some View {
        Text("\(pair.parent_name ?? "(No \(T.kind.rawValue))"), \(pair.name)")
    }
}
struct NamedPairEditor<T> : View where T: BoundPair {
    @Binding var pair: T;
    var kind: NamedPairKind = T.kind;
    
    var body: some View {
        HStack {
            TextField(T.kind.rawValue, text: Binding(
                get: { pair.parent_name ?? "" },
                set: { pair.parent_name = $0 }
            ))
            TextField(T.kind.subNamePlural(), text: $pair.name)
        }
    }
}

#Preview {
    var named_pair = Category.exampleCategories[0].children[0];
    let pair_bind: Binding = .init(
        get: {
            named_pair
        },
        set: {
            named_pair = $0
        }
    )
    
    VStack {
        NamedPairViewer(pair: named_pair)
        NamedPairEditor(pair: pair_bind)
    }.padding()
}
