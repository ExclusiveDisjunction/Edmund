//
//  Edmund.swift
//  Edmund
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore

@main
struct EdmundApp: App {
    init() {
#if DEBUG
        self.container = Containers.debugContainer;
#else
        self.container = Containers.container;
#endif
        
        self.categories = .init(container.mainContext)
         
        /*
#if os(iOS)
        registerBackgroundTasks()
#elseif os(macOS)
        refreshWidget()
#endif
         */
    }
    
    var container: ModelContainer;
    var categories: CategoriesContext?;
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
                .environment(\.categoriesContext, categories)
        }.commands {
            GeneralCommands()
        }
        .modelContainer(container)
        
        WindowGroup("Ledger", id: "ledger") {
            NavigationStack {
                LedgerTable()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup("Balance Sheet", id: "balanceSheet") {
            NavigationStack {
                BalanceSheet()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup("Bills", id: "bills") {
            NavigationStack {
                AllBillsViewEdit()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        #if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            NavigationStack {
                AllExpiredBillsVE()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        /*
        WindowGroup("Report", id: "reports", for: ReportType.self) { report in
            if let report = report.wrappedValue {
                ReportBase(kind: report)
            }
            else {
                Text("Unexpected Error")
            }
        }.modelContainer(container)
         */
        
        WindowGroup("Transaction Editor", id: "transactionEditor", for: TransactionKind.self) { kind in
            TransactionsEditor(kind: kind.wrappedValue ?? .simple)
                .preferredColorScheme(colorScheme)
                .environment(\.categoriesContext, categories)
        }.modelContainer(container)
        
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
                .preferredColorScheme(colorScheme)
        }.modelContainer(container)
    }
}
