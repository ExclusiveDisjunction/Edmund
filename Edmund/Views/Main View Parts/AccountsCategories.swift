//
//  AccountsCategories.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/4/25.
//

import SwiftUI

struct AccountsCategories : View {
    @Environment(\.modelContext) private var modelContext;
    @State private var addingAcc: Account?;
    @State private var addingSubAcc: SubAccount?;
    @State private var addingCat: Category?;
    @State private var addingSubCat: SubCategory?
    
    private var accVM: AllNamedPairsVE_MV<Account> = .init()
    private var catVM: AllNamedPairsVE_MV<Category> = .init()
    
    private func expand_all() {
        accVM.set_expansion(true)
        catVM.set_expansion(true)
    }
    private func collapse_all() {
        accVM.set_expansion(false)
        catVM.set_expansion(false)
    }
    
    var body: some View {
        TabView {
            AllNamedPairViewEdit<Account>(vm: accVM).tabItem {
                Text("Accounts")
            }
            AllNamedPairViewEdit<Category>(vm: catVM).tabItem {
                Text("Categories")
            }
        }.toolbar(id: "accountsCategoriesToolbar") {
            ToolbarItem(id: "add", placement: .primaryAction) {
                Menu {
                    Text("Accounts")
                    Button("Add Account", action: { addingAcc = .init(); modelContext.insert(addingAcc!) })
                    Button("Add Sub Account", action: { addingSubAcc = .init("", parent: nil); modelContext.insert(addingSubAcc!) })
                    
                    Divider()
                    
                    Text("Categories")
                    Button("Add Category", action: { addingCat = .init(); modelContext.insert(addingCat!) })
                    Button("Add Sub Category", action: { addingSubAcc = .init("", parent: nil); modelContext.insert(addingSubCat!) })
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            
            ToolbarItem(id: "expansion", placement: .secondaryAction) {
                ControlGroup {
                    Button(action: collapse_all) {
                        Label("Collapse All", systemImage: "arrow.up.to.line")
                    }
                    Button(action: expand_all) {
                        Label("Expand All", systemImage: "arrow.down.to.line")
                    }
                }
            }
        }.sheet(item: $addingAcc) { account in
            NamedPairParentVE(account, isEdit: true)
        }.sheet(item: $addingCat) { category in
            NamedPairParentVE(category, isEdit: true)
        }.sheet(item: $addingSubAcc) { sub_account in
            NamedPairChildVE(sub_account, isEdit: true)
        }.sheet(item: $addingSubCat) { sub_category in
            NamedPairChildVE(sub_category, isEdit: true)
        }.navigationTitle("Transaction Organization")
            .toolbarRole(.editor)
    }
}

#Preview {
    AccountsCategories().modelContainer(Containers.debugContainer)
}
