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
    
    @State private var selection = Set<EdmundCore.Category.ID>();
    
    @Bindable private var inspect = InspectionManifest<EdmundCore.Category>();
    @Bindable private var delete = DeletingManifest<EdmundCore.Category>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    
    private func deletePress() {
        let items = categories.filter { !$0.isLocked && selection.contains($0.id) }
        
        guard !items.isEmpty else {
            warning.warning = .noneSelected;
            return;
        }
        
        delete.action = items;
    }
    private func inspectPressed(mode: InspectionMode) {
        let filtered = categories.filter { selection.contains($0.id) && !$0.isLocked }
        guard let first = filtered.first, filtered.count == 1 else {
            warning.warning = filtered.isEmpty ? .noneSelected : .tooMany
            return
        }
        
        inspect.mode = .edit
        inspect.value = first
    }
    @ViewBuilder
    private func contextMenu(_ selection: Set<EdmundCore.Category.ID>) -> some View {
        let resolved = categories.filter { selection.contains($0.id) && !$0.isLocked }
        let first = resolved.first
        
        Button {
            inspect.open(Category(), mode: .add)
        } label: {
            Label("Add", systemImage: "plus")
        }
        
        Button {
            inspect.mode = .edit
            inspect.value = first
        } label: {
            Label("Edit", systemImage: "pencil")
        }.disabled(first == nil)
        
        Button {
            inspect.mode = .inspect
            inspect.value = first
        } label: {
            Label("Inspect", systemImage: "info.circle")
        }.disabled(first == nil)
        
        Button {
            delete.action = resolved
        } label: {
            Label("Delete", systemImage: "trash")
                .foregroundStyle(.red)
        }.disabled(resolved.isEmpty)
    }
    
    var body: some View {
        Table(categories, selection: $selection) {
            TableColumn("Name", value: \.name)
                .width(min: 30, ideal: 50, max: nil)
            TableColumn("") { cat in
                if cat.isLocked {
                    Image(systemName: "lock")
                }
            }
                .width(17)
            TableColumn("Description", value: \.desc)
                .width(min: 150, ideal: 170, max: nil)
        }.padding()
            .navigationTitle("Categories")
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting, titleVisibility: .visible) {
                UniqueDeletingActionConfirm(delete)
            }
            .contextMenu(forSelectionType: EdmundCore.Category.ID.self, menu: contextMenu)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inspect.open(Category(), mode: .add)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inspectPressed(mode: .edit)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inspectPressed(mode: .inspect)
                    } label: {
                        Label("Inspect", systemImage: "info.circle")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: deletePress) {
                        Label("Delete", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(item: $inspect.value) { target in
                ElementIE(target, mode: inspect.mode)
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok") {
                    warning.isPresented = false
                }
            }, message: {
                switch warning.warning ?? .noneSelected {
                    case .noneSelected: Text("Please ensure that you select at least one non-locked category.")
                    case .tooMany: Text("Please select only one category.")
                }
            })
    }
}

#Preview {
    DebugContainerView {
        CategoriesIE()
    }
}
