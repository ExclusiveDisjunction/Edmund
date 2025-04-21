//
//  SimpleElementInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import SwiftUI;
import SwiftData;

struct SimpleElementInspect<T> : ElementInspectorView where T: InspectableElement {
    typealias For = T;
    
    init(_ data: T) {
        self.data = data;
    }
    
    private var data: T;
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 80;
    let maxWidth: CGFloat = 90;
#endif
    
    var body: some View {
        HStack {
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            Text(data.name)
            
            Spacer()
        }
    }
}
