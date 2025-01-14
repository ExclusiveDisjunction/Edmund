//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;
import SwiftData;

struct CategoryPicker : View {
    init(names: NamedPair = .init()) {
        self.names = names
        self.selectedID = nil;
    }
    
    @State private var selectedID: UUID?;
    @State private var names: NamedPair;
    @State private var prev_selected_hash: Int? = nil;
    
    @State private var showing_sheet: Bool = false;
    
    @Query private var categories: [SubCategory];

    func get_account() -> SubCategory? {
        if let sel = selectedID {
            if names.hashValue == prev_selected_hash { //We already have our stuff, stored in selectedID
                return categories.first(where: { $0.id == sel })
            }
        }
        
        //Otherwise, we will look up our target based on the texts given
        return categories.first(where: { $0.parent.name == names.name && $0.name == names.sub_name} )
    }
    private func dismiss_sheet(action: NamedPickerAction) {
        switch action {
        case .cancel:
            names = .init();
            selectedID = nil;
            prev_selected_hash = nil;
            showing_sheet = false;
            
        case .ok:
            if let sel = selectedID, let cat = categories.first(where: { $0.id == sel } ) {
                self.names = .init(cat.parent.name, cat.name)
                self.prev_selected_hash = names.hashValue;
            }
            
            showing_sheet = false;
        }
    }
    
    var body: some View {
        HStack {
            NamedPairEditor(pair: $names, parent_name: "Category", child_name: "Sub Category")
            Button("...", action: {
                showing_sheet = true
            })
        }.sheet(isPresented: $showing_sheet) {
            PickerSheet(selectedID: $selectedID, mode: .category, elements: categories.to_named_pair(), on_dismiss: dismiss_sheet)
        }
    }
}
struct SubCategoryViewer : View {
    var category: SubCategory;
    
    var body: some View {
        Text("\(category.parent.name), \(category.name)")
    }
}

#Preview {
    let cat: Category = .init("Account Control")
    let sub_cat: SubCategory = .init("Pay", parent: cat)
    
    VStack {
        CategoryPicker()
        SubCategoryViewer(category: sub_cat)
    }
}
