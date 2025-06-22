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
    @State private var amount: Decimal = 0;
    @State private var date: Date = .now;
    @State private var account: SubAccount? = nil;
    private var warning = StringWarningManifest();
    
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
    
    func apply() -> [ValidationFailure]? {
        guard let categories = categoriesContext else {
            return [.internalError]
        }
        
        var result: [ValidationFailure] = [];
        
        let person = person.trimmingCharacters(in: .whitespaces)
        if person.isEmpty {
            result.append(.empty("Person"))
        }
        
        if amount < 0 {
            result.append(.negativeAmount("Amount"))
        }
        
        if let destination = account {
            let name = "Misc. Income from \(person)";
            let company = "Bank";
            let category = categories.payments.gift;
            
            let transaction = LedgerEntry(
                name: name,
                credit: amount,
                debit: 0,
                date: date,
                location: company,
                category: category,
                account: destination
            );
            modelContext.insert(transaction);
            return nil;
        }
        else {
            result.append(.empty("Account"))
            return result;
        }
    }

    var body: some View {
        TransactionEditorFrame(.miscIncome, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date).labelsHidden()
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif

                }
                
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Source", text: $person)
                        .textFieldStyle(.roundedBorder)
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
    MiscIncome()
        .modelContainer(Containers.debugContainer)
}
