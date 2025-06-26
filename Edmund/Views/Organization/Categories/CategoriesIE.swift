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
        
        if !name.isEmpty && cat.target.tryNewName(name: name, unique: uniqueEngine) {
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
                                .frame(width: 50)
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
                    Button(action: {
                        let items = cache.filter { !$0.target.isLocked && selection.contains($0.id) }
                        
                        guard !items.isEmpty else {
                            warning.warning = .noneSelected;
                            return;
                        }
                        
                        delete.action = items;
                    }) {
                        Label("Delete", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $addingCategory, onDismiss: { tmpName = ""} ) {
                CategoryAdder()
            }
            .sheet(isPresented: $addingSubCategory) {
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
    CategoriesIE()
        .modelContainer(Containers.debugContainer)
}
