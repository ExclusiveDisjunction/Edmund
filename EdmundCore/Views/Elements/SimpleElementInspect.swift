//
//  SimpleElementInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;

public struct SimpleElementInspect<T> : ElementInspectorView where T: InspectableElement {
    public typealias For = T;
    
    public init(_ data: T) {
        self.data = data;
    }
    
    private var data: T;
    
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#endif
    
    public var body: some View {
        HStack {
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            Text(data.name)
            
            Spacer()
        }
    }
}
