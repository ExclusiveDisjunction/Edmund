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
    @State var openDocuments: [EdmundSQL] = [];
    
    /*
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LedgerEntry.self,
            AccountPair.self,
            CategoryPair.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
     */
     
    var body: some Scene {
        /*
        DocumentGroup(newDocument: EdmundDocument()) { document in
            MainView( vm: .init(document.$document) )
            
        }
         */
        
        WindowGroup() {
            MainView()
        }
        
        /*.commands {
            GeneralCommands()
        }
        
        WindowGroup(id: "Balance Sheet") {
            BalanceSheet(vm: .init())
        }.modelContainer(sharedModelContainer)
        WindowGroup(id: "Ledger") {
            LedgerTable()
        }.modelContainer(sharedModelContainer)
         */
    }
}
