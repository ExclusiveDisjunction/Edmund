//
//  CategoriesIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct CategoriesIE : View {
    @Query(sort: [SortDescriptor(\EdmundCore.Category.name, order: .forward)] ) private var categories: [EdmundCore.Category];
    
    @State private var selection = Set<Category.ID>();
    @State private var addingCategory: Bool = false;
    
    @Bindable private var delete = DeletingManifest<CategoryTableRow>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    private func refresh() {
        self.cache = self.categories.map { CategoryTableRow(category: $0) }
    }
    private func deleteFromModel(data: CategoryTableRow, context: ModelContext) {
        withAnimation {
            if let category = data.target as? EdmundCore.Category {
                context.delete(category)
                Task {
                    await uniqueEngine.releaseId(key: EdmundCore.Category.objId, id: category.id)
                }
            }
            else if let subCat = data.target as? SubCategory {
                context.delete(subCat)
                Task {
                    await uniqueEngine.releaseId(key: SubCategory.objId, id: subCat.id)
                }
            }
        }
    }
    private func deletePress() {
        let items = cache.filter { !$0.target.isLocked && selection.contains($0.id) }
        
        guard !items.isEmpty else {
            warning.warning = .noneSelected;
            return;
        }
        
        delete.action = items;
    }
    
    var body: some View {
        List($cache, children: \.children, selection: $selection) { $cat in
            CategoryTableRowEdit($cat, delete: delete)
        }.padding()
            .navigationTitle("Categories")
            .task { refresh() }
            .onChange(of: categories, { _, _ in refresh() })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting, titleVisibility: .visible) {
                AbstractDeletingActionConfirm(delete, delete: deleteFromModel, post: refresh)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: deletePress) {
                        Label("Delete", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $addingCategory, onDismiss: refresh) {
                CategoryAdder()
            }
            .sheet(isPresented: $addingSubCategory, onDismiss: refresh) {
                SubCategoryAdder()
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                switch warning.warning ?? .noneSelected {
                    case .noneSelected: Text("Please ensure that you select at least one non-locked element.")
                    case .tooMany: Text("Please select only one element.")
                }
            })
    }
}

#Preview {
    DebugContainerView {
        CategoriesIE()
    }
}
