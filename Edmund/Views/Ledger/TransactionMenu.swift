//
//  TransactionMenu.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/4/25.
//

import SwiftUI
import EdmundCore

struct TransactionMenu<Label> : View where Label: View {
    var selection: Binding<TransactionKind?>? = nil;
    @ViewBuilder let label: () -> Label;
    
#if os(macOS)
    @AppStorage("preferTransWindow") private var preferTransWindow: Bool = false;
#endif
    
    @Environment(\.openWindow) private var openWindow;
    
    private func openEditor(_ kind: TransactionKind) {
#if os(macOS)
        if preferTransWindow {
            openWindow(id: "transactionEditor", value: kind)
        }
        else if let selection = selection {
            selection.wrappedValue = kind
        }
#else
        if let selection = selection {
            selection.wrappedValue = kind
        }
#endif
    }
    
    var body: some View {
        Menu {
            Menu {
                Button(TransactionKind.simple.display, action: {
                    openEditor(.simple)
                })
                Button(TransactionKind.composite.display, action: {
                    openEditor(.composite)
                })
#if os(macOS)
                Button(TransactionKind.grouped.display, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.grouped)
                })
#endif
                Button(TransactionKind.creditCard.display, action: {
                    openEditor(.creditCard)
                }).disabled(true).help("futureRelease")
            } label: {
                Text("Basic")
            }
            
            Menu {
                Button(BillsKind.bill.display, action: {
                    openEditor(.billPay(.bill))
                })
                Button(BillsKind.subscription.display, action: {
                    openEditor(.billPay(.subscription))
                })
                Button(BillsKind.utility.display, action: {
                    openEditor(.utilityPay)
                })
            } label: {
                Text("Bill Payment")
            }
            
            Menu {
                Button(TransactionKind.payday.display, action: {
                    openEditor(.payday)
                }).disabled(true).help("futureRelease")
                
                Button(TransactionKind.personalLoan.display, action: {
                    openEditor(.personalLoan)
                })
                
                Button(TransactionKind.miscIncome.display, action: {
                    openEditor(.miscIncome)
                })
                
                Button(TransactionKind.refund.display, action: {
                    openEditor(.refund)
                })
                
                Button(TransactionKind.balanceCorrection.display, action: {
                    openEditor(.balanceCorrection)
                })
                
                Button(TransactionKind.initialBalance.display, action: {
                    openEditor(.payday)
                })
            } label: {
                Text("Income")
            }
            
            Menu {
                Button(TransferKind.oneOne.display, action: {
                    openEditor(.transfer(.oneOne))
                })
                
                Button(TransferKind.oneMany.display, action: {
                    openEditor(.transfer(.oneMany))
                })
                
                Button(TransferKind.manyOne.display, action: {
                    openEditor(.transfer(.manyOne))
                })
                
                Button(TransferKind.manyMany.display, action: {
                    openEditor(.transfer(.manyMany))
                })
            } label: {
                Text("Transfer")
            }
        } label: {
            label()
        }
    }
}
