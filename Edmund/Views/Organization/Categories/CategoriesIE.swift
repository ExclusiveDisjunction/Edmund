//
//  CategoriesIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct CatNameEditor : View {
    public init(_ e: NameEditingRow, task: @escaping () async -> ()) {
        self.e = e
        self.task = task
    }
    
    @Bindable var e: NameEditingRow;
    var task: () async -> ();
    
    var body: some View {
        TextField("", text: $e.name)
            .textFieldStyle(.roundedBorder)
            .onSubmit {
                Task {
                    await task()
                }
            }
            .modifier(ShakeEffect(animatableData: e.attempts))
    }
}

struct CategoriesIE : View {
    @Query(sort: [SortDescriptor(\EdmundCore.Category.name, order: .forward)] ) private var categories: [EdmundCore.Category];
    
    @State private var cache: [CategoryWrapper] = [];
    @State private var selection: Set<SubCategoryWrapper.ID> = .init();
    
    @Bindable private var catDeleting: DeletingManifest<CategoryWrapper> = .init()
    @Bindable private var subDeleting: DeletingManifest<SubCategoryWrapper> = .init();
    @Bindable private var warning: SelectionWarningManifest = .init();
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    private func refresh() {
        self.cache = self.categories.map { CategoryWrapper($0) }
    }
    private func deleteSubCategory(data: SubCategoryWrapper, context: ModelContext) {
        let id = data.over.id;
        assert(!data.over.isLocked)
        withAnimation {
            context.delete(data.over)
        }
        
        Task {
            await uniqueEngine.releaseId(key: SubCategory.objId, id: id)
        }
    }
    private func deleteCategory(data: CategoryWrapper, context: ModelContext) {
        let id = data.over.id;
        assert(!data.over.isLocked)
        withAnimation {
            context.delete(data.over)
        }
        
        Task {
            await uniqueEngine.releaseId(key: EdmundCore.Category.objId, id: id)
        }
    }
    private func deleteSubCats(_ selection: Set<UUID>) {
        let reduced: [SubCategoryWrapper] = cache.reduce([], { old, new in
            let targets = new.children.filter { selection.contains($0.id) }
            if targets.isEmpty {
                return old
            }
            else {
                return old + targets
            }
        });
        
        if !reduced.isEmpty {
            subDeleting.action = reduced
        }
    }
    private func addCategory() {
        
    }
    private func addSubCategory(_ to: CategoryWrapper) {
        
    }
    
    @ViewBuilder
    private func subCats(_ category: CategoryWrapper) -> some View {
        ForEach(category.children) { subCat in
            HStack {
                if subCat.over.isLocked {
                    Text(subCat.over.name)
                }
                else if case .edit(let e) = subCat.state {
                    CatNameEditor(e) {
                        let _ = await subCat.state.trySwitchMode(over: subCat.over, unique: uniqueEngine)
                    }
                }
                else {
                    Text(subCat.over.name)
                        .onTapGesture(count: 2) {
                            Task {
                                let _ = await subCat.state.trySwitchMode(over: subCat.over, unique: uniqueEngine)
                            }
                        }
                }
                
                Spacer()
                
                if subCat.over.isLocked {
                    Image(systemName: "lock")
                }
            }
        }.onDelete { offsets in
            let items = category.children.enumerated().compactMap { (index, item ) in
                offsets.contains(index) ? item : nil
            };
            if items.isEmpty {
                return
            }
            
            subDeleting.action = items;
        }
    }
    
    @ViewBuilder
    private func categoryCharms(_ category: CategoryWrapper) -> some View {
        Button {
            addSubCategory(category)
        } label: {
            Image(systemName: "plus")
        }.buttonStyle(.borderless)
        
        if category.over.isLocked {
            Image(systemName: "lock.fill")
        }
        else {
            Button {
                Task {
                    let _ = await category.state.trySwitchMode(over: category.over, unique: uniqueEngine)
                }
            } label: {
                Image(systemName: category.state.isEdit ? "checkmark" : "pencil")
            }.buttonStyle(.borderless)
            
            Button {
                catDeleting.action = [category];
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }.buttonStyle(.borderless)
                .disabled(category.state.isEdit)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        List(selection: $selection) {
            ForEach(cache) { category in
                Section {
                    subCats(category)
                } header: {
                    HStack {
                        if category.over.isLocked {
                            Text(category.over.name)
                        }
                        else if case .edit(let e) = category.state {
                            CatNameEditor(e, task: {
                                let _ = await category.state.trySwitchMode(over: category.over, unique: uniqueEngine)
                            })
                        }
                        else {
                            Text(category.over.name)
                        }
                        
                        Spacer()
                        
                        categoryCharms(category)
                    }
                }
            }
        }.contextMenu(forSelectionType: SubCategoryWrapper.ID.self) { selection in
            Button {
                addCategory()
            } label: {
                Label("Add Category", systemImage: "plus")
            }
            
            Button {
                deleteSubCats(selection)
            } label: {
                Label("Delete", systemImage: "trash")
                    .foregroundStyle(.red)
            }.disabled(selection.isEmpty)
        }
    }
    
    var body: some View {
        content
            .padding()
            .alternatingRowBackgrounds()
            .navigationTitle("Categories")
            .onAppear(perform: refresh)
            //.onChange(of: categories, { _, _ in refresh() })
            .confirmationDialog("Are you sure you want to delete these sub-categories? It will remove all transactions attached to them.", isPresented: $subDeleting.isDeleting, titleVisibility: .visible) {
                AbstractDeletingActionConfirm(subDeleting, delete: deleteSubCategory, post: refresh)
            }
            .confirmationDialog("Are you sure you want to delete these categories? It will remove all sub-categories and all transactions attached to them.", isPresented: $catDeleting.isDeleting, titleVisibility: .visible) {
                AbstractDeletingActionConfirm(catDeleting, delete: deleteCategory, post: refresh)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addCategory()
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
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
        
        /*
         .sheet(isPresented: $addingCategory, onDismiss: refresh) {
         CategoryAdder()
         }
         .sheet(isPresented: $addingSubCategory, onDismiss: refresh) {
         SubCategoryAdder()
         }
         */
    }
}

#Preview {
    DebugContainerView {
        CategoriesIE()
    }
}
