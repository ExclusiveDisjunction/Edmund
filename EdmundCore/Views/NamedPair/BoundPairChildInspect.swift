//
//  BoundPairChildInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI

public struct BoundPairChildInspect<T> : ElementInspectorView where T: BoundPair {
    public typealias For = T;
    
    public init(_ data: T) {
        self.data = data;
    }
    
    private let data: T;
    
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
                
                HStack {
                    if let parent = data.parent {
                        Text(parent.name)
                    }
                    else {
                        Text("(No Parent)")
                    }
                    Spacer()
                }
            }
            GridRow {
                Text("Name")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.name)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ElementInspector(data: SubAccount.exampleSubAccount)
}
