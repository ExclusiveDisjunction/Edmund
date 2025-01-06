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
    
    var body: some View {
        Text("yo momma")
    }
}

#Preview {
    AccsAndCats()
}
