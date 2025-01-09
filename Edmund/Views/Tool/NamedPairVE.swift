//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;

struct AccountPicker : View {
    @State var account: String = "";
    @State private var sub_acc: String = "";
    @State private var show_sheet: Bool = true;
    @State private var selection: UUID? = nil;
    
    
    func get_acc() -> SubAccount {
        return .init("", parent: .init(""))
    }
    
    var body: some View {
        HStack {
            TextField("Account", text: $account)
            TextField("Sub Account", text: $sub_acc)
            Button("...", action: {
                
            })
        }.sheet(isPresented: $show_sheet, onDismiss: {
            
        }) {
            Picker("Account", selection: $selection) {
                
            }
        }
    }
}
struct SubAccountViewer : View {
    let account: SubAccount;

    var body : some View {
        Text("\(account.parent.name), \(account.name)")
    }
}
struct CategoryPicker : View {
    @State var category: String = "";
    @State var sub_cat: String = "";
    
    func get_cat() -> SubCategory {
        return .init("", parent: .init(""))
    }
    
    var body: some View {
        Text("not yet")
    }
}
struct SubCategoryViewer : View {
    let category: SubCategory;
    
    var body: some View {
        Text("\(category.parent.name), \(category.name)")
    }
}

#Preview {
    let account: Account = .init("Checking")
    var sub_acc: SubAccount = .init("", parent: account)
    let cat: Category = .init("Account Control")
    var sub_cat: SubCategory = .init("Pay", parent: cat)
    
    let acc_bind: Binding<SubAccount> = .init(
        get: {
            sub_acc
        },
        set: {
            sub_acc = $0
        }
    )
    let cat_bind: Binding<SubCategory> = .init(
        get: {
            sub_cat
        },
        set: {
            sub_cat = $0
        }
    )
    
    VStack {
        AccountPicker()
        SubAccountViewer(account: sub_acc)
        Divider()
        CategoryPicker()
        SubCategoryViewer(category: sub_cat)
    }
}
