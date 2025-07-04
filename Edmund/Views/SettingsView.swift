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
    @AppStorage("showcasePeriod") private var showcasePeriod: TimePeriods = .weekly;
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @AppStorage("showExpiredBills") private var showExpiredBills: Bool = false;
#if os(macOS)
    @AppStorage("preferTransWindow") private var preferTransWindow: Bool = false;
#endif
    
#if os(macOS)
    private let minWidth: CGFloat = 100;
    private let maxWidth: CGFloat = 110;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    static let currencyCodes: [LocaleCurrencyCode] = Locale.commonISOCurrencyCodes.map { LocaleCurrencyCode(code: $0) }
    
    @ViewBuilder
    var generalTab: some View {
        #if os(macOS)
        ScrollView {
            Grid {
                GridRow {
                    Text("Appearance")
                        .font(.headline)
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .leading)
                    
                    Spacer()
                }
                
                GridRow {
                    Text("App Theme")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $themeMode) {
                        ForEach(ThemeMode.allCases, id: \.id) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }.labelsHidden()
                        .pickerStyle(.segmented)
                }
                
                Divider()
                
                GridRow {
                    Text("Ledger")
                        .font(.headline)
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .leading)
                    
                    Spacer()
                }
                
                GridRow {
                    Text("Currency")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $currencyCode) {
                        ForEach(Self.currencyCodes, id: \.id) { code in
                            Text(code.code).tag(code.id)
                        }
                    }.labelsHidden()
                }
                
                GridRow {
                    Text("Accounting Style")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Picker("", selection: $ledgerStyle) {
                            ForEach(LedgerStyle.allCases, id: \.id) { style in
                                Text(style.description).tag(style)
                            }
                        }.labelsHidden()
                            .pickerStyle(.radioGroup)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("")
                    
                    Text("accountingStylesDesc")
                        .italic()
                }
                
                Divider()
                
                GridRow {
                    Text("Bills & Budget")
                        .font(.headline)
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .leading)
                    
                    Spacer()
                }
                
                GridRow {
                    Text("Budgeting Period")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("Budgeting Period", selection: $showcasePeriod) {
                        ForEach(TimePeriods.allCases, id: \.self) { bill in
                            Text(bill.display).tag(bill)
                        }
                    }.labelsHidden()
                }
                
                GridRow {
                    Text("")
                    
                    Text("budgetingPeriodDesc")
                        .italic()
                }
                
                GridRow {
                    Text("")
                    
                    HStack {
                        Toggle("Show Expired Bills", isOn: $showExpiredBills)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("")
                    
                    Text("showExpiredBillsDesc")
                        .italic()
                }

                Divider()
                
                GridRow {
                    Text("Miscellaneous")
                        .font(.headline)
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .leading)
                    
                    Spacer()
                }
                
                GridRow {
                    Text("")
                    
                    HStack {
                        Toggle("Prefer Transaction Window", isOn: $preferTransWindow)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("")
                    
                    Text("preferTransactionWindowDesc")
                        .italic()
                }
            }
        }
        #else
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
                        Text(style.description).tag(style)
                    }
                }
            } header: {
                Text("Styles").font(.headline)
            }
            footer: {
                Text("accountingStylesDesc")
            }
            
            Section() {
                Picker("Budgeting Period", selection: $showcasePeriod) {
                    ForEach(TimePeriods.allCases, id: \.self) { bill in
                        Text(bill.display).tag(bill)
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
            
            #if os(macOS)
            Section() {
                Toggle("Prefer Transaction Window", isOn: $preferTransWindow)
            } footer: {
                Text("preferTransactionWindowDesc")
            }
            #endif
        }.padding()
        #endif
    }
    
    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            ScrollView {
                HomepageEditor(isSheet: false)
                    .padding()
                #if os(iOS)
                    .frame(minHeight: 500)
                #endif
            }.tabItem {
                Label("Homepage", systemImage: "rectangle.3.group")
            }
        }.padding()
    }
}

#Preview {
    SettingsView()
}
