//
//  SettingsView.swift
//  Edmund
//
//  Created by Hollan on 3/30/25.
//

import SwiftUI

enum ThemeMode : String, Identifiable, CaseIterable {
    case light = "Light", dark = "Dark", system = "System"
    
    var id: Self { self }
}

enum LedgerStyle: String, Identifiable, CaseIterable {
    case none = "Do not show as Accounting Style", standard = "Standard Accounting Style", reversed = "Reversed Accounting Style"
    
    var id: Self { self }
}

struct SettingsView : View {
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("enableTransactions") private var enableTransactions: Bool = true
    @AppStorage("showcasePeriod") private var showcasePeriod: BillsPeriod = .weekly;
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system;
    
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
                Picker("Accounting Style", selection: $ledgerStyle) {
                    ForEach(LedgerStyle.allCases, id: \.id) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            } header: {
                Text("Styles")
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
            
            Section(header: Text("Appearance")) {
                Picker("App Theme", selection: $themeMode) {
                    ForEach(ThemeMode.allCases, id: \.id) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }
        }.padding()
    }
}

#Preview {
    SettingsView()
}
