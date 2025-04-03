//
//  ui_demoApp.swift
//  ui-demo
//
//  Created by Hollan on 11/3/24.
//

import SwiftUI
import SwiftData

@main
struct ui_demoApp: App {
    @Environment(\.openWindow) var openWindow;
    
    /*
#if DEBUG
    var sharedModelContainer = Containers.previewContainer
#else
    var sharedModelContainer = Containers.sharedModelContainer
#endif
    */
    
    var sharedModelContainer = Containers.sharedModelContainer

    var body: some Scene {
        WindowGroup {
            MainView()
        }.modelContainer(sharedModelContainer).commands {
            GeneralCommands()
        }
        
        WindowGroup(id: "Balance Sheet") {
            NavigationStack {
                BalanceSheet(vm: .init())
            }
        }.modelContainer(sharedModelContainer)
        WindowGroup(id: "Ledger") {
            NavigationStack {
                LedgerTable()
            }
        }.modelContainer(sharedModelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
