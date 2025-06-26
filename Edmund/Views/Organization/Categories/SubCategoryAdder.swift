//
//  SubCategoryAdder.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/25/25.
//

import SwiftData
import SwiftUI

struct SubCategoryAdder : View {
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)] ) private var categories: [Category];
    
    @State private var name: String = "";
    @State private var parent: Category? = nil;
    @State private var nameAttempts: CGFloat = 0;
    @State private var parentAttempts: CGFloat = 0;
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) private var modelContext;
    
#if os(macOS)
    private let minWidth: CGFloat = 50;
    private let maxWidth: CGFloat = 60;
#else
    private let minWidth: CGFloat = 55;
    private let maxWidth: CGFloat = 65;
#endif
    
    private func submit() {
        let name = name.trimmingCharacters(in: .whitespaces)
        
        
        if let parent = parent {
            let target = SubCategory(parent: parent)
            if target.tryNewName(name: name, unique: uniqueEngine) {
                target.setNewName(name: name, unique: uniqueEngine)
                print("name accepted, value: \(target.id)")
                modelContext.insert(target)
                
                dismiss()
                return
            }
        
            withAnimation(.default) {
                nameAttempts += 1;
            }
        }
        else {
            withAnimation(.default) {
                parentAttempts += 1;
            }
        }
    }
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text("Category:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $parent) {
                        Text("None")
                            .tag(nil as Category?)
                        
                        ForEach(categories, id: \.id) { category in
                            Text(category.name)
                                .tag(category)
                        }
                    }.labelsHidden()
                        .modifier(ShakeEffect(animatableData: parentAttempts))
                }
                
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", text: $name)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .textFieldStyle(.roundedBorder)
                        .modifier(ShakeEffect(animatableData: nameAttempts))
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel", action: { dismiss() } )
                    .buttonStyle(.bordered)
                
                Button("Done", action: submit)
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    SubCategoryAdder()
        .modelContainer(Containers.debugContainer)
}
