//
//  Audit.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI
import EdmundCore

struct Audit: TransactionEditorProtocol {
    @State private var account: SubAccount? = nil;
    @State private var date: Date = .now;
    @State private var amount: Decimal = 0;
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let account = account else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError")
            return false
        }
        
        let transaction = LedgerEntry(
            name: "Audit",
            credit: amount >= 0 ? amount : 0,
            debit: amount < 0 ? -amount : 0,
            date: date,
            location: "Bank",
            category: categories.accountControl.audit,
            account: account
        );
        
        modelContext.insert(transaction);
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.audit, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Account:")
                    NamedPairPicker($account)
                }
                GridRow {
                    Text("Amount:")
                    TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                }
                GridRow {
                    Text("Date:")
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        
                        Spacer()
                    }
                }
            }
        })
    }
}

#Preview {
    Audit()
        .padding()
        .modelContainer(Containers.debugContainer)
}
