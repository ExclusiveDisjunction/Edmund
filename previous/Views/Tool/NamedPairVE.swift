//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;

struct AccountNameEditor : View {
    @Binding var account: AccountPair;
    
    var body: some View {
        HStack {
            TextField("Account", text: $account.account)
            TextField("Sub Account", text: $account.sub_account)
        }
    }
}
struct AccountNameViewer : View {
    var account: AccountPair;
    
    var body: some View {
        Text("\(account.account) . \(account.sub_account)")
    }
}

struct CategoryNameEditor : View {
    @Binding var category: CategoryPair;
    
    var body: some View {
        TextField("Category", text: $category.category)
        TextField("Sub Category", text: $category.sub_category)
    }
}
struct CategoryNameViewer : View {
    var category: CategoryPair;
    
    var body: some View {
        Text("\(category.category) . \(category.sub_category)")
    }
}

#Preview {
    var acc: AccountPair = .init("Checking", "")
    var cat: CategoryPair = .init("Account Control", "Pay")
    
    let acc_bind: Binding<AccountPair> = .init(
        get: {
            acc
        },
        set: {
            acc = $0
        }
    )
    let cat_bind: Binding<CategoryPair> = .init(
        get: {
            cat
        },
        set: {
            cat = $0
        }
    )
    
    VStack {
        AccountNameEditor(account: acc_bind)
        AccountNameViewer(account: acc)
        Divider()
        CategoryNameEditor(category: cat_bind)
        CategoryNameViewer(category: cat)
    }
}
