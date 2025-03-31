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

#Preview {
    let named_pair = SubCategory.exampleSubCategory

    NamedPairViewer(pair: named_pair).padding()
}
