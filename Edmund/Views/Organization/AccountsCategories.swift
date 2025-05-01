//
//  AccountsCategories.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/4/25.
//

import SwiftUI
import SwiftData
import EdmundCore

@Observable
class AccountsCategoriesVM {
    init() {
        accVM = .init()
        catVM = .init()
    }
    
    var accVM: AllNamedPairsVE_MV<Account>;
    var catVM: AllNamedPairsVE_MV<EdmundCore.Category>;
    
    func refresh(acc: [Account], cat: [EdmundCore.Category]) {
        accVM.refresh(acc)
        catVM.refresh(cat)
    }
}


struct AccountsCategories : View {
    @Environment(\.modelContext) private var modelContext;
    @State private var addingAcc: Account?;
    @State private var addingSubAcc: SubAccount?;
    @State private var addingCat: EdmundCore.Category?;
    @State private var addingSubCat: SubCategory?
    
    @Query private var accounts: [Account];
    @Query private var categories: [EdmundCore.Category];
    
    var vm: AccountsCategoriesVM;
    
    private func expand_all() {
        vm.accVM.set_expansion(true)
        vm.catVM.set_expansion(true)
    }
    private func collapse_all() {
        vm.accVM.set_expansion(false)
        vm.catVM.set_expansion(false)
    }
    private func refresh() {
        vm.refresh(acc: accounts, cat: categories)
    }
    
    var body: some View {
        TabView {
            AllNamedPairViewEdit<Account>(vm: vm.accVM).tabItem {
                Text("Accounts")
            }
            AllNamedPairViewEdit<EdmundCore.Category>(vm: vm.catVM).tabItem {
                Text("Categories")
            }
        }.toolbar(id: "accountsCategoriesToolbar") {
            ToolbarItem(id: "add", placement: .primaryAction) {
                Menu {
                    Text("Accounts")
                    Button("Add Account", action: {
                        addingAcc = .init();
                        vm.accVM.data.append(.init(addingAcc!))
                        modelContext.insert(addingAcc!)
                        
                    } )
                    Button("Add Sub Account", action: {
                        addingSubAcc = .init("", parent: nil);
                        modelContext.insert(addingSubAcc!)
                    })
                    
                    Divider()
                    
                    Text("Categories")
                    Button("Add Category", action: {
                        addingCat = .init();
                        modelContext.insert(addingCat!)
                    })
                    Button("Add Sub Category", action: {
                        addingSubAcc = .init("", parent: nil);
                        vm.catVM.data.append(.init(addingCat!))
                        modelContext.insert(addingSubCat!)
                    })
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            ToolbarItem(id: "refresh", placement: .primaryAction) {
                Button(action: self.refresh) {
                    Label("Refresh", systemImage: "arrow.trianglehead.clockwise")
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
            ElementEditor(account, adding: true)
        }.sheet(item: $addingCat) { category in
            ElementEditor(category, adding: true)
        }.sheet(item: $addingSubAcc) { sub_account in
            ElementEditor(sub_account, adding: true)
        }.sheet(item: $addingSubCat) { sub_category in
            ElementEditor(sub_category, adding: true)
        }.navigationTitle("Organization")
            .toolbarRole(.editor)
            .onAppear(perform: self.refresh)
    }
}

#Preview {
    AccountsCategories(vm: .init()).modelContainer(Containers.debugContainer)
}
