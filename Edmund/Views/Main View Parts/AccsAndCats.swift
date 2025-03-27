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
            Text("Showing Accounts")
                .tabItem {
                    Text("Accounts")
                }
            
            Text("Showing Categories")
                .tabItem {
                    Text("Categories")
                }
        }
    }
}

#Preview {
    AccsAndCats()
}
