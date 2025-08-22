//
//  Refund.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct Refund : TransactionEditorProtocol {
    @State private var company: String = "";
    @State private var reason: String = "";
    @State private var date: Date = Date.now;
    @State private var account: Account? = nil;
    @Bindable private var amount: CurrencyValue = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let minWidth: CGFloat = 75;
    let maxWidth: CGFloat = 85;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let company = company.trimmingCharacters(in: .whitespaces)
        let reason = reason.trimmingCharacters(in: .whitespaces)
        let amount = amount.rawValue;
        
        guard let destination = account, !company.isEmpty && !reason.isEmpty else {
            return .empty
        }
        
        let transaction = LedgerEntry(
            name: "Refund for \(reason)",
            credit: amount,
            debit: 0,
            date: date,
            location: company,
            category: categories.income,
            account: destination
        );
        
        modelContext.insert(transaction);
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.refund, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Company:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Company", text: $company)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Amount")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("For Item:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Item", text: $reason)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Deposit:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($account)
                }
            }
        })
    }
}

#Preview {
    DebugContainerView {
        Refund()
    }
}
