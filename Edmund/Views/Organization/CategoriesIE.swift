//
//  CategoriesIE.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/19/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct CategoryTableRow : Identifiable {
    init(subCategory: SubCategory) {
        self.id = UUID();
        self.target = subCategory;
        self.name = subCategory.name;
        self.children = nil;
    }
    init(category: EdmundCore.Category) {
        self.id = UUID();
        self.target = category;
        self.name = category.name;
        self.children = category.children?.map { Self(subCategory: $0) }
    }
    
    let target: any InspectableElement
    let id: UUID;
    let name: String;
    let children: [CategoryTableRow]?;
}

struct CategoriesIE : View {
    @Query(sort: [SortDescriptor(\EdmundCore.Category.name, order: .forward)] ) private var categories: [EdmundCore.Category];
    @State private var selection = Set<CategoryTableRow.ID>();
    @State private var cache: [CategoryTableRow] = [];
    
    @Bindable private var inspecting = InspectionManifest<CategoryTableRow>();
    @Bindable private var delete = DeletingManifest<CategoryTableRow>();
    @Bindable private var warning = WarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        self.cache = self.categories.map { CategoryTableRow(category: $0) }
    }
    private func deleteFromModel(data: CategoryTableRow, context: ModelContext) {
        withAnimation {
            if let category = data.target as? EdmundCore.Category {
                context.delete(category)
            }
            else if let SubCategory = data.target as? SubCategory {
                context.delete(SubCategory)
            }
        }
    }
    
    var body: some View {
        VStack {
            List(cache, children: \.children, selection: $selection) { acc in
                Text(acc.name)
            }.contextMenu(forSelectionType: AccountTableRow.ID.self) {
                SelectionContextMenu($0, data: cache, inspect: inspecting, delete: delete, warning: warning, canView: false)
            }
        }.padding()
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Category") {
                            inspecting.open(.init(category: .init()), mode: .add)
                        }
                        Button("Sub Category") {
                            inspecting.open(.init(subCategory: .init()), mode: .add)
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                
                GeneralIEToolbarButton(on: cache, selection: $selection, inspect: inspecting, warning: warning, role: .edit, placement: .primaryAction)
                
                GeneralDeleteToolbarButton(on: cache, selection: $selection, delete: delete, warning: warning)
                
            }.task { refresh() }
            .sheet(item: $inspecting.value) { item in
                if let category = item.target as? EdmundCore.Category {
                    ElementEditor(category, adding: inspecting.mode == .add)
                }
                else if let subCategory = item.target as? SubCategory {
                    ElementEditor(subCategory, adding: inspecting.mode == .add)
                }
            }
            .alert("Warning", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: {
                    warning.isPresented = false
                })
            }, message: {
                Text((warning.warning ?? .noneSelected).message )
            })
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting) {
                AbstractDeletingActionConfirm(delete, delete: deleteFromModel, post: refresh)
            }
    }
}

#Preview {
    CategoriesIE()
        .modelContainer(Containers.debugContainer)
}
