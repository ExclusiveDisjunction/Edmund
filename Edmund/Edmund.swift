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
        
        if let allData = try? RegistryData(container.mainContext) {
            uniqueEngine = .init(allData)
        }
        else {
            print("Unable to extract information out of the main context, setting the unique engine to default.")
            uniqueEngine = .init();
        }
         
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
    var uniqueEngine: UniqueEngine;
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
                .environment(\.uniqueEngine, uniqueEngine)
        }.commands {
            GeneralCommands()
        }
        .modelContainer(container)
        
        WindowGroup(PageDestinations.home.rawValue, id: PageDestinations.home.key) {
            NavigationStack {
                Homepage()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.ledger.rawValue, id: PageDestinations.ledger.key) {
            NavigationStack {
                LedgerTable()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.balance.rawValue, id: PageDestinations.balance.key) {
            NavigationStack {
                BalanceSheet()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.bills.rawValue, id: PageDestinations.bills.key) {
            NavigationStack {
                AllBillsViewEdit()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.budget.rawValue, id: PageDestinations.budget.key) {
            NavigationStack {
                BudgetIE()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.org.rawValue, id: PageDestinations.org.key) {
            NavigationStack {
                OrganizationHome()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.accounts.rawValue, id: PageDestinations.accounts.key) {
            NavigationStack {
                AccountsIE()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.categories.rawValue, id: PageDestinations.categories.key) {
            NavigationStack {
                CategoriesIE()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.credit.rawValue, id: PageDestinations.credit.key) {
            NavigationStack {
                CreditCardHelper()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.audit.rawValue, id: PageDestinations.audit.key) {
            NavigationStack {
                BalanceVerifier()
                    .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        /* For the next version, tee hee
        WindowGroup(PageDestinations.pay.rawValue, id: PageDestinations.pay.key) {
            NavigationStack {
                
                .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.paychecks.rawValue, id: PageDestinations.paychecks.key) {
            NavigationStack {
                
                .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        
        WindowGroup(PageDestinations.taxes.rawValue, id: PageDestinations.taxes.key) {
            NavigationStack {
                
                .preferredColorScheme(colorScheme)
            }
        }.modelContainer(container)
        */
        
        WindowGroup(PageDestinations.jobs.rawValue, id: PageDestinations.jobs.key) {
            NavigationStack {
                AllJobsViewEdit()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
            }
        }.modelContainer(container)
        
        #if os(macOS)
        WindowGroup("Expired Bills", id: "expiredBills") {
            NavigationStack {
                AllExpiredBillsVE()
                    .preferredColorScheme(colorScheme)
                    .environment(\.uniqueEngine, uniqueEngine)
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
    }
}
