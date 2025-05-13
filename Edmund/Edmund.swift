//
//  ui_demoApp.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

@main
struct EdmundApp: App {
    init() {
        self.container = Containers.container;
        
#if os(iOS)
        registerBackgroundTasks()
#elseif os(macOS)
        refreshWidget()
#endif
    }
    
    var container: ModelContainer;
    @AppStorage("themeMode") private var themeMode: ThemeMode?;
    
    var colorScheme: ColorScheme? {
        switch themeMode {
            case .light: return .light
            case .dark: return .dark
            default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(colorScheme)
                .modelContainer(container)
        }.commands {
            GeneralCommands()
        }
        
        WindowGroup("Ledger", id: "ledger") {
            NavigationStack {
                LedgerTable()
                    .preferredColorScheme(colorScheme)
                    .modelContainer(container)
            }
        }
        
        WindowGroup("Balance Sheet", id: "balanceSheet") {
            NavigationStack {
                BalanceSheet(vm: .init())
                    .preferredColorScheme(colorScheme)
                    .modelContainer(container)
            }
        }
        
        WindowGroup("Bills", id: "bills") {
            NavigationStack {
                AllBillsViewEdit()
                    .preferredColorScheme(colorScheme)
                    .modelContainer(container)
            }
        }
        
        #if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            NavigationStack {
                AllExpiredBillsVE()
                    .preferredColorScheme(colorScheme)
                    .modelContainer(container)
            }
        }
        
        WindowGroup("Report", id: "reports", for: ReportType.self) { report in
            if let report = report.wrappedValue {
                ReportBase(kind: report)
            }
            else {
                Text("Unexpected Error")
            }
        }
        
        Window("About", id: "about") {
            AboutView()
                .preferredColorScheme(colorScheme)
        }
        
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
        #endif
        
        WindowGroup("Help", id: "help") {
            HelpView()
                .preferredColorScheme(colorScheme)
        }
        
        WindowGroup("Credit Helper", id: "creditHelper") {
            CreditCardHelper()
                .modelContainer(container)
                .preferredColorScheme(colorScheme)
        }
    }
}
