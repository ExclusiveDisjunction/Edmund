//
//  InitialBalance.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/3/25.
//

import EdmundCore
import SwiftUI
import SwiftData

struct InitialBalance : TransactionEditorProtocol {
    @State private var account: Account? = nil;
    @State private var date: Date = .now;
    @Bindable private var amount: CurrencyValue = .init();
    
#if os(macOS)
    let minWidth: CGFloat = 75;
    let maxWidth: CGFloat = 85;
#else
    let minWidth: CGFloat = 100;
    let maxWidth: CGFloat = 110;
#endif
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categories;
    
    func apply() -> ValidationFailure? {
        guard let account = account else {
            return .empty
        }
        guard let categories = categories else {
            return .internalError
        }
        
        guard amount.rawValue >= 0 else {
            return .negativeAmount
        }
        
        let transaction = LedgerEntry(
            name: "Initial Balance",
            credit: amount.rawValue,
            debit: 0,
            date: date,
            location: NSLocalizedString("Bank", comment: ""),
            category: categories.adjustments,
            account: account
        )
        modelContext.insert(transaction)
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.initialBalance, apply: apply) {
            Grid {
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($account)
                }
                
                GridRow {
                    Text("Balance:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        
                        Button("Today") {
                            date = .now
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }

}
