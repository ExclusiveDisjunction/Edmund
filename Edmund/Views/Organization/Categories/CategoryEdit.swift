//
//  CategoryEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/24/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct CategoryEdit : View {
    @Bindable var snapshot: CategorySnapshot;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("", text: $snapshot.name)
            }
            
            GridRow {
                Text("Description:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextEditor(text: $snapshot.desc)
                    .frame(minHeight: 130, idealHeight: 170, maxHeight: nil)
            }
        }
    }
}

#Preview {
    ElementEditor(Category(), adding: false)
}
