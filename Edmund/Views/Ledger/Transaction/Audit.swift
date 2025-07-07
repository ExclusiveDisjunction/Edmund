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
    @Bindable private var amount: CurrencyValue = .init();
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 70;
    private let maxWidth: CGFloat = 80;
#endif
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let amount = amount.rawValue;
        guard let account = account else {
            return .empty
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
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.audit, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($account)
                        .namedPairPickerStyle(horizontalSizeClass == .compact ? .vertical : .horizontal)
                }
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        
                        Button("Today") {
                            date = .now
                        }
                        
                        Spacer()
                    }
                }
            }
        })
    }
}

#Preview {
    DebugContainerView {
        Audit()
            .padding()
    }
}
