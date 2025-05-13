//
//  AvailableCreditEdit.swift
//  Edmund
//
//  Created by Hollan on 5/13/25.
//

import SwiftUI
import EdmundCore

struct AvailableCreditEdit: View {
    @Binding var targets: [BalanceVerifyRow]
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        Table($targets) {
            TableColumn("Name") { $target in
                Text(target.name)
            }
            TableColumn("Available Credit") { $target in
                TextField("", value: $target.avalibleCredit, format: .currency(code: currencyCode))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

#Preview {
    let accounts = [
        Account("Account A", creditLimit: 100),
        Account("Account B", creditLimit: 400)
    ];
    var targets = [
        BalanceVerifyRow(account: accounts[0], balance: 50),
        BalanceVerifyRow(account: accounts[1], balance: 200)
    ]
    let binding = Binding(get: { targets }, set: { targets = $0 } )
    
    AvailableCreditEdit(targets: binding)
        .padding()
}
