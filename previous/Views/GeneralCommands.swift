//
//  GeneralCommands.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;

struct GeneralCommands : Commands {
    @Environment(\.openWindow) var openWindow;
    
    var body: some Commands {
        CommandMenu("Ledger") {
            Button("Show Balance Sheet") {
                openWindow(id: "Balance Sheet")
            }.keyboardShortcut("b", modifiers: [.command, .shift])
            Button("Show Ledger") {
                openWindow(id: "Ledger")
            }.keyboardShortcut("l", modifiers: [.command, .shift])
        }
    }
}
