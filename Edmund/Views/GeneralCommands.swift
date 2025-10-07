//
//  GeneralCommands.swift
//  Edmund
//
//  Created by Hollan on 1/1/25.
//

import SwiftUI;

struct GeneralCommands : Commands {
    @Environment(\.openWindow) var openWindow;
    @Environment(\.openURL) private var openURL;
    
    @FocusedValue(\.currentPage) var currentPage;
    
    @AppStorage("showLedgerFooter") private var showLedgerFooter: Bool = true;
#if os(macOS)
    @AppStorage("preferTransWindow") private var preferTransWindow: Bool = false;
#endif
    
    var body: some Commands {
        CommandMenu("Ledger") {
            Button("Ledger") {
                openWindow(id: "ledger")
            }.keyboardShortcut("l", modifiers: [.command])
            
            Button("Balance Sheet") {
                openWindow(id: "balanceSheet")
            }.keyboardShortcut("b", modifiers: [.command, .shift])
            
            Divider()
            
#if os(macOS)
            TransactionMenu {
                Text("Transaction Templates")
            }
#endif
            
            Divider()
            
            Toggle("Show Ledger Footer", isOn: $showLedgerFooter)
                .disabled(currentPage != .ledger)
            
            Toggle("Use Transaction Windows", isOn: $preferTransWindow)
                .disabled(currentPage != .ledger)
            
            /*
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
             */
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
            
            Button("Report a bug...") {
                openURL(bugFormLink)
            }
            Button("Request a feature...") {
                openURL(featureFormLink)
            }
        }
    }
}
