//
//  AccountsCategories.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/4/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct OrganizationHome : View {
    @Query private var accounts: [Account];
    @Query private var categories: [EdmundCore.Category];
    
    var body: some View {
        HStack(spacing: 10) {
            GeometryReader { geometry in
                VStack {
                    Text("Accounts")
                    List(accounts) { account in
                        Text(account.name)
                    }
                }
            }
            
            GeometryReader { geometry in
                VStack {
                    Text("Categories")
                    List(categories) { category in
                        Text(category.name)
                    }
                }
            }
        }.padding().navigationTitle("Organization")
    }
}

#Preview {
    DebugContainerView {
        OrganizationHome()
    }
}
