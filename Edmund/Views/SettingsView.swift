//
//  SettingsView.swift
//  Edmund
//
//  Created by Hollan on 3/30/25.
//

import SwiftUI

struct SettingsView : View {
#if os(iOS)
    @AppStorage("showAsBalances") private var showAsBalances: Bool = true;
#else
    @AppStorage("showAsBalances") private var showAsBalances: Bool = false;
#endif
    
    @AppStorage("enableTransactions") private var enableTransactions: Bool = true;
    
    var body: some View {
        Form {
            Section() {
                Toggle("Enable Transactions", isOn: $enableTransactions)
                Toggle("Show As Balances", isOn: $showAsBalances)
            } header: {
                Text("Transactions")
            } footer: {
                Text("If transactions are enabled, all ledger & transaction data/forms can be accessed. If this is off, then these features will be hidden and non-accessible. Disable this feature if you want to use the budgeting and bill tracking features only. \nWhen transactions are showed as balances, the difference of credit and debit of each transaction is shown, instead of the individual parts.")
            }
        }.padding()
    }
}

#Preview {
    SettingsView()
}
