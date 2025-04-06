//
//  AllExpiredBillsVE.swift
//  Edmund
//
//  Created by Hollan on 4/5/25.
//

import SwiftUI
import SwiftData

struct AllExpiredBillsVE : View {
    @Query private var bills: [Bill];
    
    init() {
        self._bills = Query(FetchDescriptor<Bill>())
    }
    
    var body: some View {
        VStack {
            
        }.navigationTitle("Expired Bills")
    }
}

#Preview {
    NavigationStack {
        AllExpiredBillsVE().modelContainer(Containers.debugContainer)
    }
}
