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
        VStack {
            if targets.isEmpty {
                Text("There are no accounts with credit limits to modify.")
                    .italic()
            }
            else {
                Grid {
                    GridRow {
                        Text("Account")
                            .bold()
                        Text("Credit Limit")
                            .bold()
                    }
                    Divider()
                    
                    ForEach($targets, id: \.id) { $target in
                        GridRow {
                            Text(target.name)
                        
                            TextField("", value: $target.avalibleCredit, format: .currency(code: currencyCode))
                                .textFieldStyle(.roundedBorder)
#if os(iOS)
                                .keyboardType(.decimalPad)
#endif
                        }
                    }
                }
            }
        }.padding()
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
