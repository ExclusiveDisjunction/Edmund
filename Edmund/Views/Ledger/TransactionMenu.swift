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
                Button(TransactionKind.simple.name, action: {
                    openEditor(.simple)
                })
                Button(TransactionKind.composite.name, action: {
                    openEditor(.composite)
                })
#if os(macOS)
                Button(TransactionKind.grouped.name, action: {
                    openWindow(id: "transactionEditor", value: TransactionKind.grouped)
                })
#endif
                Button(TransactionKind.creditCard.name, action: {
                    openEditor(.creditCard)
                }).disabled(true).help("futureRelease")
            } label: {
                Text("Basic")
            }
            
            Menu {
                Button(BillsKind.bill.name, action: {
                    openEditor(.billPay(.bill))
                })
                Button(BillsKind.subscription.name, action: {
                    openEditor(.billPay(.subscription))
                })
                Button(BillsKind.utility.name, action: {
                    openEditor(.utilityPay)
                })
            } label: {
                Text("Bill Payment")
            }
            
            Menu {
                Button(TransactionKind.payday.name, action: {
                    openEditor(.payday)
                }).disabled(true).help("futureRelease")
                Button(TransactionKind.personalLoan.name, action: {
                    openEditor(.personalLoan)
                })
                
                Button(TransactionKind.miscIncome.name, action: {
                    openEditor(.miscIncome)
                })
                
                Button(TransactionKind.refund.name, action: {
                    openEditor(.refund)
                })
            } label: {
                Text("Income")
            }
            
            Menu {
                Button(TransferKind.oneOne.name, action: {
                    openEditor(.transfer(.oneOne))
                })
                
                Button(TransferKind.oneMany.name, action: {
                    openEditor(.transfer(.oneMany))
                })
                
                Button(TransferKind.manyOne.name, action: {
                    openEditor(.transfer(.manyOne))
                })
                
                Button(TransferKind.manyMany.name, action: {
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
