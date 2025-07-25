//
//  GeneralIncome.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI
import EdmundCore

struct MiscIncome: TransactionEditorProtocol {
    @State private var person: String = "";
    @Bindable private var amount: CurrencyValue = .init();
    @State private var date: Date = .now;
    @State private var account: SubAccount? = nil;
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let person = person.trimmingCharacters(in: .whitespaces)
        guard let destination = account, !person.isEmpty else {
            return .empty
        }
        guard amount >= 0.0 else {
            return .negativeAmount
        }
        
        
        let name = "Misc. Income from \(person)";
        let company = "Bank";
        let category = categories.payments.gift;
        
        let transaction = LedgerEntry(
            name: name,
            credit: amount.rawValue,
            debit: 0,
            date: date,
            location: company,
            category: category,
            account: destination
        );
        modelContext.insert(transaction);
        return nil;
    }

    var body: some View {
        TransactionEditorFrame(.miscIncome, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Source", text: $person)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date).labelsHidden()
                        
                        Button("Today") { date = .now }
                        
                        Spacer()
                    }
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
    DebugContainerView {
        MiscIncome()
    }
}
