//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;

struct AccountPicker : View {
    
    var body: some View {
        Text("not yet")
    }
}
struct SubAccountViewer : View {
    var account: SubAccount;
    
    var body : some View {
        Text("comming")
    }
}
struct CategoryPicker : View {
    var body: some View {
        Text("not yet")
    }
}
struct SubCategoryViewer : View {
    var category: SubCategory;
    
    var body: some View {
        Text("comming")
    }
}

#Preview {
    var account: Account = .init("Checking")
    var sub_acc: SubAccount = .init("", parent: account)
    var cat: Category = .init("Account Control")
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
