//
//  CategoryInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI

/// The inspector view for `Category`.
public struct CategoryInspect : ElementInspectorView {
    public typealias For = EdmundCore.Category;
    
    public init(_ data: Category) {
        self.data = data;
    }
    
    private var data: Category;
    
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#endif
    
    public var body: some View {
        HStack {
            Text("Name:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            Text(data.name)
            
            Spacer()
        }
    }
}

#Preview {
    ElementInspector(data: Category.exampleCategory)
}
