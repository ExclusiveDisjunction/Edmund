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
    
    var sharedModelContainer: ModelContainer = ModelController.sharedModelContainer

    var body: some Scene {
        WindowGroup {
            MainView()
            
        } .modelContainer(sharedModelContainer).commands {
            GeneralCommands()
        }
        
        WindowGroup(id: "Balance Sheet") {
            BalanceSheet(vm: .init())
        }.modelContainer(sharedModelContainer)
        WindowGroup(id: "Ledger") {
            LedgerTable()
        }.modelContainer(sharedModelContainer)
    }
}
