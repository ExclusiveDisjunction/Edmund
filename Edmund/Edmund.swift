//
//  Edmund.swift
//  Edmund
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

@main
struct EdmundApp: App {
    init() {
        let log = LoggerSystem();
        self.stack = DataStack.shared
        self.help = HelpEngine(log.help);
        self.loader = AppLoaderEngine(help: help, log: log)
    
        let state = AppLoadingState();
        self.state = state
        self.log = log
        
        Task(priority: .high) { [loader] in
            await loader.loadApp(state: state)
        }
    }
    
    let stack: DataStack;
    let log: LoggerSystem;
    let help: HelpEngine;
    let loader: AppLoaderEngine;
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
            AppWindowGate(appLoader: self.loader, state: self.state) {
                MainView()
            }
        }.commands {
            //GeneralCommands()
        }
        
        /*
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
        
        WindowGroup(PageDestinations.expiredBills.rawValue, id: PageDestinations.expiredBills.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    AllExpiredBillsVE()
                }
            }
        }
        
        WindowGroup(PageDestinations.incomeDivider.rawValue, id: PageDestinations.incomeDivider.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    IncomeDivisions()
                }
            }
        }
        
        WindowGroup(PageDestinations.budget.rawValue, id: PageDestinations.budget.key) {
            NavigationStack {
                AppWindowGate(appLoader: loader, state: state) {
                    Budgets()
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
         */
    }
}
