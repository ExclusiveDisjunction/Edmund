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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        inspect.open(Category(), mode: .add)
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
            .sheet(item: $inspect.value) { target in
                ElementIE(target, mode: inspect.mode)
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok") {
                    warning.isPresented = false
                }
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
