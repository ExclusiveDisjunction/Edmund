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
        self.loader = .init()
    }
    
    var loader: AppLoader;
    
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
            AppWindowGate(loader: loader) {
                MainView()
            }
        }.commands {
            GeneralCommands()
        }
        
        WindowGroup(PageDestinations.home.rawValue, id: PageDestinations.home.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    Homepage()
                }
            }
        }
        
        WindowGroup(PageDestinations.ledger.rawValue, id: PageDestinations.ledger.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    LedgerTable()
                }
            }
        }
        
        WindowGroup(PageDestinations.balance.rawValue, id: PageDestinations.balance.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    BalanceSheet()
                }
            }
        }
        
        WindowGroup(PageDestinations.bills.rawValue, id: PageDestinations.bills.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllBillsViewEdit()
                    
                }
            }
        }
        
        WindowGroup(PageDestinations.budget.rawValue, id: PageDestinations.budget.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllBudgetsInspect()
                }
            }
        }
        
        WindowGroup(PageDestinations.org.rawValue, id: PageDestinations.org.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    OrganizationHome()
                }
            }
        }
        
        WindowGroup(PageDestinations.accounts.rawValue, id: PageDestinations.accounts.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AccountsIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.categories.rawValue, id: PageDestinations.categories.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    CategoriesIE()
                }
            }
        }
        
        WindowGroup(PageDestinations.credit.rawValue, id: PageDestinations.credit.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    CreditCardHelper()
                }
            }
        }
        
        WindowGroup(PageDestinations.audit.rawValue, id: PageDestinations.audit.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    BalanceVerifier()
                }
            }
        }
        
        WindowGroup(PageDestinations.jobs.rawValue, id: PageDestinations.jobs.key) {
            NavigationStack {
                AppWindowGate(loader: loader) {
                    AllJobsViewEdit()
                }
            }
        }
        
        WindowGroup("Transaction Editor", id: "transactionEditor", for: TransactionKind.self) { kind in
            TransactionsEditor(kind: kind.wrappedValue ?? .simple)
        }
        
#if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            NavigationStack {
                AppWindowGate(loader: loader) {
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
                .preferredColorScheme(colorScheme)
        }
#endif
        
        WindowGroup("Help", id: "help") {
            /*
            HelpView()
                .preferredColorScheme(colorScheme)
            */
        }
    }
}
