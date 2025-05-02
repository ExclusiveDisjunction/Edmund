//
//  GeneralCommands.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;
import EdmundCore

struct GeneralCommands : Commands {
    @Environment(\.openWindow) var openWindow;
    
    var body: some Commands {
        CommandMenu("Ledger") {
            Button("Ledger") {
                openWindow(id: "ledger")
            }.keyboardShortcut("l", modifiers: [.command])
            
            Button("Balance Sheet") {
                openWindow(id: "balanceSheet")
            }.keyboardShortcut("b", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Initialize Ledger") {
                
            }
            
            Button("Reset Ledger") {
                
            }
            
            Divider()
            
            Menu {
                Button("Edmund Formatting") {
                    
                }
                Button("CSV") {
                    
                }
            } label: {
                Text("Import Data")
            }
            
            Menu {
                Button("Edmund Formatting") {
                    
                }
                Button("CSV") {
                    
                }
            } label: {
                Text("Export Data")
            }
            
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
            }
        }
        
        CommandMenu("Bills") {
            Button("Bills") {
                openWindow(id: "bills")
            }.keyboardShortcut("b", modifiers: [.command])
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
