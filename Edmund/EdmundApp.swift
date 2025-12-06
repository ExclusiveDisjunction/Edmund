//
//  EdmundApp.swift
//  Edmund
//
//  Created by Hollan Sellars on 12/6/25.
//

import SwiftUI
import CoreData

@main
struct EdmundApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
