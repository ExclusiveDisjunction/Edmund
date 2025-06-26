//
//  CategoriesIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData

@Observable
final class CategoryTableRow : Identifiable, Parentable {
    init(subCategory: SubCategory) {
        self.id = UUID();
        self.target = subCategory;
        self.children = nil;
        self.name = subCategory.name;
    }
    init(category: Category) {
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

struct CategoriesIE : View {
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)] ) private var categories: [Category];
    
    @State private var selection = Set<CategoryTableRow.ID>();
    @State private var cache: [CategoryTableRow] = [];
    @State private var addingCategory: Bool = false;
    @State private var addingSubCategory: Bool = false;
    
    @State private var editingParent: Category?;
    @State private var tmpName: String = "";
    
    @Bindable private var delete = DeletingManifest<CategoryTableRow>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    private func refresh() {
        self.cache = self.categories.map { CategoryTableRow(category: $0) }
    }
    private func deleteFromModel(data: CategoryTableRow, context: ModelContext) {
        withAnimation {
            if let category = data.target as? Category {
                context.delete(category)
            }
            else if let SubCategory = data.target as? SubCategory {
                context.delete(SubCategory)
            }
        }
    }
    private func submitFor(_ cat: CategoryTableRow) {
        let name = cat.name.trimmingCharacters(in: .whitespaces);
        
        if cat.target.tryNewName(name: name, unique: uniqueEngine) {
            cat.target.setNewName(name: name, unique: uniqueEngine);
            cat.isEditing = false;
        }
        else {
            withAnimation(.default) {
                cat.attempts += 1;
            }
        }
    }
    
    private static let lockedWarning: LocalizedStringKey = "This category is required for Edmund to create transactions automatically, and cannot be edited/deleted.";
    
    
    @ToolbarContentBuilder
    private var catToolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "add", placement: .primaryAction) {
            Menu {
                Button("Category", action: {
                    addingCategory = true
                })
                
                Button("Sub Category", action: {
                    addingSubCategory = true
                })
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        
        GeneralDeleteToolbarButton(on: cache, selection: $selection, delete: delete, warning: warning)
    }
    
    var body: some View {
        VStack {
            List($cache, children: \.children, selection: $selection) { $cat in
                Text(cat.target.name)
                    .onTapGesture(count: 2) {
                        if !cat.target.isLocked {
                            cat.isEditing = true
                        }
                    }
                    .popover(isPresented: $cat.isEditing) {
                        HStack {
                            Text("Name:")
                            TextField("", text: $cat.name)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit{
                                    submitFor(cat)
                                }
                                .onDisappear {
                                    cat.name = cat.target.name
                                }
                                .modifier(ShakeEffect(animatableData: CGFloat(cat.attempts)))
                        }.padding()
                    }.contextMenu {
                        Button(action: {
                            cat.isEditing = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }.disabled(cat.target.isLocked)
                            .help(cat.target.isLocked ? Self.lockedWarning : "")
                        
                        Button(action: {
                            delete.action = [cat]
                        }) {
                            Label("Delete", systemImage: "trash")
                        }.disabled(cat.target.isLocked)
                            .foregroundStyle(.red)
                            .help(cat.target.isLocked ? Self.lockedWarning : "")
                    }
            }
        }.padding()
            .navigationTitle("Categories")
            .task { refresh() }
            .onChange(of: categories, { _, _ in refresh() })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting) {
                AbstractDeletingActionConfirm(delete, delete: deleteFromModel, post: refresh)
            }
            .toolbar(id: "categoriesToolbar") {
                catToolbar
            }
            .sheet(isPresented: $addingCategory, onDismiss: { tmpName = ""} ) {
                CategoryAdder()
            }
            .sheet(isPresented: $addingSubCategory) {
                SubCategoryAdder()
            }
        /*
            
            .toolbar(id: "categoriesToolbar") {
                catToolbar
            }
            .sheet(item: $inspecting.value) { item in
                if let category = item.target as? Category {
                    ElementIE(category, mode: inspecting.mode)
                }
                else if let subCategory = item.target as? SubCategory {
                    ElementIE(subCategory, mode: inspecting.mode)
                }
            }
            .toolbarRole(.editor)
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
                     */
    }
}

#Preview {
    CategoriesIE()
        .modelContainer(Containers.debugContainer)
}
