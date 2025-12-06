//
//  CategoryInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/24/25.
//

import SwiftUI
import SwiftData

struct CategoryInspect : View {
    @Bindable var data: Category;
    
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
                
                HStack {
                    Text(data.name)
                    
                    Spacer()
                }
            }
            
            GridRow {
                VStack {
                    Text("Description:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    Spacer()
                }
                
                TextEditor(text: $data.desc)
                    .frame(minHeight: 130, idealHeight: 170, maxHeight: nil)
            }
        }
    }
}

#Preview {
    ElementInspector(data: Category.exampleCategory)
}
