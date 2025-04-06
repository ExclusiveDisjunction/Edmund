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
            Button("Balance Sheet") {
                openWindow(id: "balanceSheet")
            }.keyboardShortcut("b", modifiers: [.command, .shift])
            Button("Ledger") {
                openWindow(id: "ledger")
            }.keyboardShortcut("l", modifiers: [.command, .shift])
        }
    }
}
