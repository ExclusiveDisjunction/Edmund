//
//  GeneralCommands.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;

struct GeneralCommands : Commands {
    @Environment(\.openWindow) var openWindow;
    @FocusedValue(\.currentPage) var currentPage;
    
    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Divider()
            
            if let $currentPage = currentPage {
                Picker("Current Page", selection: $currentPage) {
                    Text(PageDestinations.home.rawValue).tag(PageDestinations.home)
                    
                    ForEach(PageDestinations.groups) { group in
                        Section(group.name) {
                            ForEach(group.content) { page in
                                Text(page.rawValue).tag(page)
                            }
                        }
                    }
                }
            }
        }
        
        CommandMenu("Ledger") {
            Button("Ledger") {
                openWindow(id: "ledger")
            }.keyboardShortcut("l", modifiers: [.command])
            
            Button("Balance Sheet") {
                openWindow(id: "balanceSheet")
            }.keyboardShortcut("b", modifiers: [.command, .shift])
            
            Divider()
            
            TransactionMenu {
                Text("Transaction Templates")
            }
            
            Divider()
            
            Button("Initialize Ledger") {
                
            }.disabled(true)
            
            Button("Reset Ledger") {
                
            }.disabled(true)
            
            Divider()
            
            Button("Export", action: {
                
            }).disabled(true)
            
            Button("Import", action: {
                
            }).disabled(true)
            
            #if os(macOS)
            
            Divider()
            
            Menu {
                Button("Spending Report") {
                    openWindow(id: "reports", value: ReportType.spending)
                }
                Button("Balance Sheet") {
                    openWindow(id: "reports", value: ReportType.balances)
                }
                Button("Transactions List") {
                    openWindow(id: "reports", value: ReportType.transactions)
                }
            } label: {
                Text("Generate Report")
            }.disabled(true)
            
            #endif
        }
        
        CommandMenu("Bills") {
            Button("Bills") {
                openWindow(id: "bills")
            }.keyboardShortcut("b", modifiers: [.command, .option])
            Button("Expired Bills") {
                openWindow(id: "expiredBills")
            }.keyboardShortcut("e", modifiers: [.command, .shift])
        }
        
        CommandGroup(replacing: CommandGroupPlacement.help) {
            Button("Help") {
                openWindow(id: "help")
            }
            Button("About") {
                openWindow(id: "about")
            }
        }
    }
}
