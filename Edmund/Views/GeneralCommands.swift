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
            
            Menu {
                Text("Basic Templates")
                    .disabled(true)
                
                Button(TransactionKind.simple.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.simple)
                })
                Button(TransactionKind.composite.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.composite)
                })
#if os(macOS)
                Button(TransactionKind.grouped.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.grouped)
                })
#endif
                Button(TransactionKind.creditCard.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.creditCard)
                }).disabled(true).help("futureRelease")
                
                Divider()
                
                Text("Bill Payments").disabled(true)
                
                Button(BillsKind.bill.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.billPay(.bill))
                })
                Button(BillsKind.subscription.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.billPay(.subscription))
                })
                Button(BillsKind.utility.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.utilityPay)
                })
                
                Divider()
                
                Text("Income").disabled(true)
                
                Button(TransactionKind.payday.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.payday)
                }).disabled(true).help("futureRelease")
                Button(TransactionKind.personalLoan.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.personalLoan)
                })
                Button(TransactionKind.miscIncome.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.miscIncome)
                })
                
                Button(TransactionKind.refund.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.refund)
                })
                
                Divider()
                
                Text("Transfers").disabled(true)
                
                Button(TransferKind.oneOne.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.transfer(.oneOne))
                })
                
                Button(TransferKind.oneMany.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.transfer(.oneMany))
                })
                
                Button(TransferKind.manyOne.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.transfer(.manyOne))
                })
                
                Button(TransferKind.manyMany.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.transfer(.manyMany))
                })
            } label: {
                Text("Transaction Templates")
            }
            
            Divider()
            
            Button("Initialize Ledger") {
                
            }.disabled(true)
            
            Button("Reset Ledger") {
                
            }.disabled(true)
            
            Divider()
            
            Menu {
                Button("Edmund Formatting") {
                    
                }
                Button("CSV") {
                    
                }
            } label: {
                Text("Import Data")
            }.disabled(true)
            
            Menu {
                Button("Edmund Formatting") {
                    
                }
                Button("CSV") {
                    
                }
            } label: {
                Text("Export Data")
            }.disabled(true)
            
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
