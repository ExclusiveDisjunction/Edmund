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
                Picker("Accounting Style", selection: $ledgerStyle) {
                    ForEach(LedgerStyle.allCases, id: \.id) { style in
                        Text(style.display).tag(style)
                    }
                }
            } header: {
                Text("Styles").font(.headline)
            }
            footer: {
                Text("accountingStylesDesc").font(.subheadline)
            }
            
            Section() {
                Picker("Budgeting Period", selection: $showcasePeriod) {
                    ForEach(BillsPeriod.allCases, id: \.self) { bill in
                        Text(bill.name).tag(bill)
                    }
                }
            } footer: {
                Text("budgetingPeriodDesc")
            }
            
            Section() {
                Toggle("Show Expired Bills", isOn: $showExpiredBills)
            } footer: {
                Text("showExpiredBillsDesc")
            }
        }.padding()
    }
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            HomepageEditor()
                .padding()
                .tabItem {
                    Label("Homepage", systemImage: "rectangle.3.group")
                }
        }.padding()
    }
}

#Preview {
    SettingsView()
}
