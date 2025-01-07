//
//  AccsAndCats.swift
//  Edmund
//
//  Created by Hollan on 1/6/25.
//

import SwiftUI
import SwiftData

struct AccsAndCats : View {
    @Query var accs: [AccountPair];
    @Query var cats: [CategoryPair];
    @State var show_accs: Bool = true;
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    show_accs = true
                }) {
                    Text("Accounts").font(.headline).padding(5)
                }.buttonStyle(.link).foregroundStyle(show_accs ? Color.accentColor : Color.primary).border(show_accs ? Color.accentColor : Color.primary, width: show_accs ? 2 : 0).cornerRadius(2)
                Button(action: {
                    show_accs = false
                }) {
                    Text("Categories").font(.headline).padding(5)
                }.buttonStyle(.link).foregroundStyle(!show_accs ? Color.accentColor : Color.primary).border(!show_accs ? Color.accentColor : Color.primary, width: !show_accs ? 2 : 0).cornerRadius(2)
            }
            
            if show_accs {
                Text("Showing Accounts")
                Spacer()
            }
            else {
                Text("Showing Categories")
                Spacer()
            }
        }.padding()
    }
}

#Preview {
    AccsAndCats()
}
