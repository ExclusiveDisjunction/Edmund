//
//  BalanceVerifier.swift
//  Edmund
//
//  Created by Hollan on 5/12/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct BalanceVerifier: View {
    
    var body: some View {
        VStack {
            Text("Work in Progress")
        }.navigationTitle("Balance Verification")
    }
}

#Preview {
    BalanceVerifier()
        .modelContainer(Containers.debugContainer)
        .padding()
        .navigationTitle("Balance Verification")
}
