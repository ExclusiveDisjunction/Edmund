//
//  Edmund.swift
//  Edmund
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData
import EdmundCore
import EdmundWidgetCore

@main
struct EdmundApp: App {
    init() {
        let log = LoggerSystem();
        let help = HelpEngine(log.help);
        let unique = UniqueEngine(log.unique);
        let loader = AppLoaderEngine(unique: unique, help: help, log: log)
        
        self.help = help
        self.unique = unique
        self.loader = loader
    
        let state = AppLoadingState();
        self.state = state
        self.log = log
        
        Task {
            await loader.loadApp(state: state)
        }
    }
    
    let log: LoggerSystem;
    let loader: AppLoaderEngine;
    let help: HelpEngine;
    let unique: UniqueEngine;
    let state: AppLoadingState;
    
    @AppStorage("themeMode") private var themeMode: ThemeMode?;
    
    private var colorScheme: ColorScheme? {
        switch themeMode {
            case .light: return .light
            case .dark: return .dark
            default: return nil
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            AppWindowGate(appLoader: loader, state: state) {
                MainView()
            }
        }.commands {
            GeneralCommands()
        }
        
        WindowGroup(PageDestinations.home.rawValue, id: PageDestinations.home.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    Homepage()
                }
            }
        }
        
        WindowGroup(PageDestinations.ledger.rawValue, id: PageDestinations.ledger.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    LedgerTable()
                }
            }
        }
        
        WindowGroup(PageDestinations.balance.rawValue, id: PageDestinations.balance.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    BalanceSheet()
                }
            }
        }
        
        WindowGroup(PageDestinations.bills.rawValue, id: PageDestinations.bills.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    AllBillsViewEdit()
                    
                }
            }
        }
        
        WindowGroup(PageDestinations.incomeDivider.rawValue, id: PageDestinations.incomeDivider.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    AllIncomeDivisionsIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.budget.rawValue, id: PageDestinations.budget.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    Text("Work in progress")
                }
            }
        }
        
        WindowGroup(PageDestinations.accounts.rawValue, id: PageDestinations.accounts.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    AccountsIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.categories.rawValue, id: PageDestinations.categories.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    CategoriesIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.audit.rawValue, id: PageDestinations.audit.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    Auditor()
                }
            }
        }
        
        WindowGroup(PageDestinations.jobs.rawValue, id: PageDestinations.jobs.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    AllJobsViewEdit()
                }
            }
        }
        
        WindowGroup("Transaction Editor", id: "transactionEditor", for: TransactionKind.self) { kind in
            AppWindowGate(appLoader: loader, state: state) {
                TransactionsEditor(kind: kind.wrappedValue ?? .simple)
            }
        }
        
#if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    AllExpiredBillsVE()
                }
            }
        }
        
        Window("About", id: "about") {
            AboutView()
                .preferredColorScheme(colorScheme)
        }
        
        Settings {
            SettingsView()
                .environment(\.helpEngine, help)
                .preferredColorScheme(colorScheme)
        }
#endif
        
        WindowGroup("Help", id: "help") {
            HelpTreePresenter()
                .environment(\.helpEngine, help)
                .preferredColorScheme(colorScheme)
        }
    }
}
