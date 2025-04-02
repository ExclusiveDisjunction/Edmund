//
//  SettingsView.swift
//  Edmund
//
//  Created by Hollan on 3/30/25.
//

import SwiftUI

struct SettingsView : View {

    @AppStorage("accountingStyle") private var accountingStyle: Bool = true;
    @AppStorage("enableTransactions") private var enableTransactions: Bool = true
    @AppStorage("showcasePeriod") private var showcasePeriod: BillsPeriod = .weekly;
    
    var body: some View {
        Form {
            Section() {
                Toggle("Enable Transactions", isOn: $enableTransactions)
            } header: {
                Text("Transactions")
            } footer: {
                Text("If transactions are enabled, all ledger & transaction data/forms can be accessed. If this is off, then these features will be hidden and non-accessible. Disable this feature if you want to use the budgeting and bill tracking features only.")
            }
            
            Section() {
                Toggle("Accounting Style Ledger", isOn: $accountingStyle)
            } header: {
                Text("Accounting Style")
            }
                footer: {
                Text("When accouning mode is enabled, instead of showing 'Balance' on the Ledger, 'Credit' and 'Debit' are showed independently.")
            }
            
            Section() {
                Picker("Budgeting Period", selection: $showcasePeriod) {
                    ForEach(BillsPeriod.allCases, id: \.self) { bill in
                        Text(bill.rawValue).tag(bill)
                    }
                }
            }
        }.padding()
    }
}

#Preview {
    SettingsView()
}
