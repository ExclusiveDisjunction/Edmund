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
    }
    init(category: Category) {
        self.id = UUID();
        self.target = category;
        self.children = category.children.map { Self(subCategory: $0) }
    }
    
    var target: any PairBasis
    let id: UUID;
    var newName: String = "";
    var children: [CategoryTableRow]?;
    var isEditing: Bool = false;
}

struct CategoriesIE : View {
    @Query(sort: [SortDescriptor(\Category.name, order: .forward)] ) private var categories: [Category];
    @State private var selection = Set<CategoryTableRow.ID>();
    @State private var cache: [CategoryTableRow] = [];
    
    @Bindable private var inspecting = ParentInspectionManifest<CategoryTableRow>();
    @Bindable private var delete = DeletingManifest<CategoryTableRow>();
    @Bindable private var warning = SelectionWarningManifest();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
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
    
    @ToolbarContentBuilder
    private var catToolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "add", placement: .primaryAction) {
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
        
        GeneralIEToolbarButton(on: cache, selection: $selection, inspect: inspecting, warning: warning, role: .inspect, placement: .primaryAction)
        
        GeneralDeleteToolbarButton(on: cache, selection: $selection, delete: delete, warning: warning, placement: .primaryAction)
    }
    
    var body: some View {
        VStack {
            List($cache, editActions: [.delete], children: \.children, selection: $selection) { $cat in
                if cat.isEditing{
                    TextField("Name", text: $cat.target.name)
                }
                else {
                    Text(cat.target.name)
                }
            }
            /*
             .contextMenu(forSelectionType: CategoryTableRow.ID.self) { selection in
             SelectionContextMenu(selection, data: cache, inspect: inspecting, delete: delete, warning: warning)
             }
             */
        }.padding()
            .navigationTitle("Categories")
            .toolbar(id: "categoriesToolbar") {
                catToolbar
            }.task { refresh() }
            .onChange(of: categories, { _, _ in refresh() })
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
            .confirmationDialog("deleteItemsConfirm", isPresented: $delete.isDeleting) {
                AbstractDeletingActionConfirm(delete, delete: deleteFromModel, post: refresh)
            }
    }
}

#Preview {
    CategoriesIE()
        .modelContainer(Containers.debugContainer)
}
