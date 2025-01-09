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
    init() {
        do {
            self.newDocument = .init(data: try .init(source: nil))
        } catch {
            fatalError("Unable to create new document")
        }
    }
    
    @Environment(\.openWindow) var openWindow;
    @State var openDocuments: [EdmundSQL] = [];
    private var newDocument: EdmundDocument;
    
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
        
        DocumentGroup(newDocument: newDocument) { document in
            MainView(
                document: document.$document,
                vm: .init(document.document.data)
            )
        }
        
        /*
        
        WindowGroup() {
            Welcome()
        }
        
        WindowGroup("Edmund", id: "main", for: UUID.self) { id in
            if let id = id.wrappedValue, let document = openDocuments.first(where: { $0.id == id }) {
                MainView(vm: .init(document))
            }
        }
         */
        
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
