//
//  AccsAndCats.swift
//  Edmund
//
//  Created by Hollan on 1/6/25.
//

import SwiftUI
import SwiftData

struct AccsAndCats : View {
    @State var show_accs: Bool = true;
    
    var body: some View {
        TabView {
            Tab("Accounts", systemImage: "") {
                Text("Showing Accounts")
            }


            Tab("Categories", systemImage: "") {
                Text("Showing Categories")
            }
        }
    }
}

#Preview {
    AccsAndCats()
}
