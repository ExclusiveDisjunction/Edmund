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
    @State private var amount: Decimal = 0;
    @State private var date: Date = Date.now;
    @State private var account: SubAccount? = nil;
    private var warning = StringWarningManifest();
    
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
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError")
            return false
        }
        
        guard let destination = account else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        guard !company.isEmpty && !reason.isEmpty else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        guard amount >= 0 else {
            warning.warning = .init(message: "negativeAmount")
            return false;
        }
        
        let transaction = LedgerEntry(
            name: "Refund for \(reason)",
            credit: amount,
            debit: 0,
            date: date,
            location: company,
            category: categories.payments.refund,
            account: destination
        );
        
        modelContext.insert(transaction);
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.refund, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Company:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                }
                
                GridRow {
                    Text("Amount")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                }
                
                GridRow {
                    Text("For Item:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }
                
                GridRow {
                    Text("Deposit:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($account)
                }
            }
        })
    }
}

#Preview {
    Refund()
        .modelContainer(Containers.debugContainer)
}
