//
//  NamedPair.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI;

struct NamedPairViewer<T>: View where T: NamedPair {
    @State var pair: T;
    
    var body: some View {
        Text("\(pair.parent_name), \(pair.child_name)")
    }
}
struct NamedPairEditor<T> : View where T: NamedPair {
    @Binding var pair: T;
    var kind: NamedPairKind = T.kind;
    
    var body: some View {
        HStack {
            switch kind {
            case .account:
                TextField("Account", text: $pair.parent_name)
                TextField("Sub Account", text: $pair.child_name)
            case .category:
                TextField("Category", text: $pair.parent_name)
                TextField("Sub Category", text: $pair.child_name)
            case .nondetermined:
                TextField("Parent", text: $pair.parent_name)
                TextField("Child", text: $pair.child_name)
            }
        }
    }
}

#Preview {
    var named_pair: UnboundNamedPair = .init("Father", "Son");
    let pair_bind: Binding<UnboundNamedPair> = .init(
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
