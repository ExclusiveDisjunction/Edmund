//
//  NamedPair.swift
//  Edmund
//
//  Created by Hollan on 1/14/25.
//

import SwiftUI;
import EdmundCore

/// A simple abstraction that allows for the displaying of a named pair couple as "Parent, Child" name.
public struct CompactNamedPairInspect<T>: View where T: BoundPair {
    public init(_ pair: T?) {
        self.pair = pair
    }
    private let pair: T?;
    
    public var body: some View {
        if let pair = self.pair {
            if let parent = pair.parent {
                Text("\(parent.name), \(pair.name)")
            }
            else {
                Text("(No parent), \(pair.name)")
            }
        }
        else {
            Text("(No information)")
        }
    }
}

#Preview {
    let named_pair = SubCategory.exampleSubCategory

    CompactNamedPairInspect(named_pair).padding()
}
