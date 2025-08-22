//
//  CategoryTableRow.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/26/25.
//

import SwiftUI
import SwiftData
import EdmundCoreImm

@Observable
final class CategoryTableRow : Identifiable, Parentable {
    init(subCategory: SubCategory) {
        self.id = UUID();
        self.target = subCategory;
        self.children = nil;
        self.name = subCategory.name;
    }
    init(category: EdmundCoreImm.Category) {
        self.id = UUID();
        self.target = category;
        self.children = category.children.map { Self(subCategory: $0) }
        self.name = category.name;
    }
    
    var target: any CategoryBase
    let id: UUID;
    var name: String;
    var children: [CategoryTableRow]?;
    var isEditing: Bool = false;
    var attempts: CGFloat = 0;
}

struct CategoryTableRowEdit : View {
    init(_ data: Binding<CategoryTableRow>, delete: DeletingManifest<CategoryTableRow>) {
        self._data = data
        self.delete = delete;
    }
    
    private let delete: DeletingManifest<CategoryTableRow>;
    @Binding private var data: CategoryTableRow;
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    private static let lockedWarning: LocalizedStringKey = "This category is required for Edmund to create transactions automatically, and cannot be edited/deleted.";
    
    @MainActor
    private func submitFor(_ cat: CategoryTableRow) async {
        let name = cat.name.trimmingCharacters(in: .whitespaces);
        
        if !name.isEmpty {
            if await cat.target.tryNewName(name: name, unique: uniqueEngine) {
                await cat.target.setNewName(name: name, unique: uniqueEngine)
                cat.isEditing = false;
                return
            }
        }
        
        withAnimation(.default) {
            cat.attempts += 1;
        }
    }
    
    var body: some View {
        HStack {
            Text(data.target.name)
                .popover(isPresented: $data.isEditing) {
                    HStack {
                        Text("Name:")
                            .frame(width: 50)
                        TextField("", text: $data.name)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                Task {
                                    await submitFor(data)
                                }
                            }
                            .onDisappear {
                                data.name = data.target.name
                            }
                            .modifier(ShakeEffect(animatableData: CGFloat(data.attempts)))
                    }.padding()
                }
            
            Spacer()
            
            if data.target.isLocked {
                Image(systemName: "lock.fill")
            }
        }
            .onTapGesture(count: 2) {
                if !data.target.isLocked {
                    data.isEditing = true
                }
            }
            .contextMenu {
                Button(action: {
                    data.isEditing = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }.disabled(data.target.isLocked)
                    .help(data.target.isLocked ? Self.lockedWarning : "")
                
                Button(action: {
                    delete.action = [data]
                }) {
                    Label("Delete", systemImage: "trash")
                }.disabled(data.target.isLocked)
                    .foregroundStyle(.red)
                    .help(data.target.isLocked ? Self.lockedWarning : "")
            }
    }
}

#Preview {
    var data = CategoryTableRow(category: Category.exampleCategory)
    let binding = Binding(get: { data }, set: { data = $0 } )
    
    CategoryTableRowEdit(binding, delete: .init())
        .padding()
}
