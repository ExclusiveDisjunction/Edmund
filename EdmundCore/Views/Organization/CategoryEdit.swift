//
//  CategoryEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/21/25.
//

import SwiftUI

/// The editor view for `Category`.
public struct CategoryEdit: ElementEditorView  {
    public typealias For = EdmundCore.Category;
    
    @Bindable private var snapshot: CategorySnapshot;
    public init(_ snapshot: CategorySnapshot){
        self.snapshot = snapshot;
    }
    
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
            
            TextField("", text: $snapshot.name)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    ElementEditor(Category.exampleCategory, adding: false)
}
