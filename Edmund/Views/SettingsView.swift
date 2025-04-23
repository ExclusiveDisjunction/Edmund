//
//  SettingsView.swift
//  Edmund
//
//  Created by Hollan on 3/30/25.
//

import SwiftUI
import EdmundCore

enum ThemeMode : String, Identifiable, CaseIterable {
    case light = "Light", dark = "Dark", system = "System"
    
    var id: Self { self }
}

struct LocaleCurrencyCode : Identifiable {
    var code: String;
    var id: String { code }
}

struct SettingsView : View {
    @AppStorage("ledgerStyle") private var ledgerStyle: LedgerStyle = .none;
    @AppStorage("enableTransactions") private var enableTransactions: Bool = true
    @AppStorage("showcasePeriod") private var showcasePeriod: BillsPeriod = .weekly;
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @AppStorage("showExpiredBills") private var showExpiredBills: Bool = false;
    
    static let currencyCodes: [LocaleCurrencyCode] = Locale.commonISOCurrencyCodes.map { LocaleCurrencyCode(code: $0) }
    
    @ViewBuilder
    var generalTab: some View {
        Form {
            Section(header: Text("Appearance").font(.headline)) {
                Picker("App Theme", selection: $themeMode) {
                    ForEach(ThemeMode.allCases, id: \.id) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                
                Picker("Currency", selection: $currencyCode) {
                    ForEach(Self.currencyCodes, id: \.id) { code in
                        Text(code.code).tag(code.id)
                    }
                }
            }
            
            Section() {
                Toggle("Use Ledger", isOn: $enableTransactions)
            } header: {
                Text("Ledger").font(.headline)
            } footer: {
                Text("If transactions are enabled, all ledger & transaction data/forms can be accessed. If this is off, then these features will be hidden and non-accessible. Disable this feature if you want to use the budgeting and bill tracking features only.").font(.subheadline)
            }
            
            Section() {
                Picker("Accounting Style", selection: $ledgerStyle) {
                    ForEach(LedgerStyle.allCases, id: \.id) { style in
                        Text(style.display).tag(style)
                    }
                }
            } header: {
                Text("Styles").font(.headline)
            }
            footer: {
                Text("When accouning mode is enabled, instead of showing 'Balance' on the Ledger, 'Credit' and 'Debit' are showed independently.").font(.subheadline)
            }
            
            Section() {
                Picker("Budgeting Period", selection: $showcasePeriod) {
                    ForEach(BillsPeriod.allCases, id: \.self) { bill in
                        Text(bill.name).tag(bill)
                    }
                }
            }
            
            Section() {
                Toggle("Show Expired Bills", isOn: $showExpiredBills)
            } footer: {
                Text("showExpiredBillsDesc")
            }
        }.padding()
    }
    
    @ViewBuilder
    private var profilesTab: some View {
        VStack {
            Text("profileDescription", comment: "A pharagraph explaining what profiles are, why they exists, and general actions").font(.title2)
            
            VStack {
                List {
                    
                }
                
                HStack {
                    Button(action: {
                        
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                    
                    Button(action: {
                        
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        
                    }) {
                        Label("Delete", systemImage: "trash").foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            profilesTab
                .tabItem {
                    Label("Profiles", systemImage: "person.circle")
                }
        }.padding()
    }
}

#Preview {
    SettingsView()
}
