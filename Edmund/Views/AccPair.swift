//
//  AccPair.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI;

struct AccPair : View {
    @State var acc: Binding<AccountPair>;
    
    var body: some View {
        HStack {
            TextField("Account", text: acc.account)
            TextField("Sub Account", text: acc.sub_account)
        }
    }
}

#Preview {
    AccPair(acc: Binding<AccountPair>(
        get: {
            AccountPair(account: "Test", sub_account: "Sub Test")
        },
        set: { _ in
            
        }
    ))
}
