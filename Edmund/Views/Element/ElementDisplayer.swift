//
//  ElementDisplayer.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import SwiftUI

public struct ElementDisplayer<T> : View where T: NamedElement {
    public let value: T?;
    
    public var body: some View {
        if let value = self.value {
            Text(value.name)
        }
        else {
            Text("(No information)")
                .italic()
        }
    }
}

public struct EnumDisplayer<T> : View where T: Displayable {
    public let value: T;
    
    public var body: some View {
        Text(value.display)
    }
}
