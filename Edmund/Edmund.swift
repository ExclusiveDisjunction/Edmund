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
    
        /*
         #if os(iOS)
         registerBackgroundTasks()
         #elseif os(macOS)
         refreshWidget()
         #endif
         */
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
            AppWindowGate(loader: loader) {
                Homepage()
            }
        }
        
        WindowGroup(PageDestinations.ledger.rawValue, id: PageDestinations.ledger.key) {
            AppWindowGate(loader: loader) {
                LedgerTable()
            }
        }
        
        WindowGroup(PageDestinations.balance.rawValue, id: PageDestinations.balance.key) {
            AppWindowGate(loader: loader) {
                BalanceSheet()
            }
        }
        
        WindowGroup(PageDestinations.bills.rawValue, id: PageDestinations.bills.key) {
            AppWindowGate(loader: loader) {
                AllBillsViewEdit()
                
            }
        }
        
        WindowGroup(PageDestinations.budget.rawValue, id: PageDestinations.budget.key) {
            AppWindowGate(loader: loader) {
                AllBudgetsInspect()
            }
        }
        
        WindowGroup(PageDestinations.org.rawValue, id: PageDestinations.org.key) {
            AppWindowGate(loader: loader) {
                OrganizationHome()
            }
        }
        
        WindowGroup(PageDestinations.accounts.rawValue, id: PageDestinations.accounts.key) {
            AppWindowGate(loader: loader) {
                AccountsIE()
            }
        }
        
        WindowGroup(PageDestinations.categories.rawValue, id: PageDestinations.categories.key) {
            AppWindowGate(loader: loader) {
                CategoriesIE()
            }
        }
        
        WindowGroup(PageDestinations.credit.rawValue, id: PageDestinations.credit.key) {
            AppWindowGate(loader: loader) {
                CreditCardHelper()
            }
        }
        
        WindowGroup(PageDestinations.audit.rawValue, id: PageDestinations.audit.key) {
            AppWindowGate(loader: loader) {
                BalanceVerifier()
            }
        }
        
        WindowGroup(PageDestinations.jobs.rawValue, id: PageDestinations.jobs.key) {
            AppWindowGate(loader: loader) {
                AllJobsViewEdit()
            }
        }
        
        WindowGroup("Transaction Editor", id: "transactionEditor", for: TransactionKind.self) { kind in
            TransactionsEditor(kind: kind.wrappedValue ?? .simple)
        }
        
#if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            AppWindowGate(loader: loader) {
                AllExpiredBillsVE()
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
    }
}
