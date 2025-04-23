//
//  NamedPair.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI;

public struct NamedPairViewer<T>: View where T: BoundPair {
    public init(_ pair: T) {
        self.pair = pair
    }
    public let pair: T;
    
    public var body: some View {
        Text("\(pair.parent_name ?? "(No \(T.kind.rawValue))"), \(pair.name)")
    }
}

#Preview {
    let named_pair = SubCategory.exampleSubCategory

    NamedPairViewer(named_pair).padding()
}
