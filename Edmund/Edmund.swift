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
        
        #if os(macOS)
        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
        #endif
        
        WindowGroup(id: "help") {
            HelpView()
                .preferredColorScheme(colorScheme)
        }
    }
}
