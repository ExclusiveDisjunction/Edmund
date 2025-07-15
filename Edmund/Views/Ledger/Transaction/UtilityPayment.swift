//
//  UtilityPayment.swift
//  Edmund
//
//  Created by Hollan on 4/21/25.
//

import SwiftUI
import SwiftData;
import EdmundCore

struct UtilityPayment : TransactionEditorProtocol {
    @Query private var utilities: [Utility];
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.categoriesContext) private var categoriesContext;
    @Environment(\.modelContext) private var modelContext;
    
    @State private var selected: Utility?;
    @State private var account: SubAccount?;
    @State private var date: Date = .now;
    @State private var doStore: Bool = true;
    @State private var cache: [Utility] = [];
    @Bindable private var amount: CurrencyValue = .init();
    private var warning = StringWarningManifest();
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        cache = utilities.filter { !$0.isExpired }.sorted(by: { $0.name < $1.name } )
    }
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        let amount = amount.rawValue;
        guard amount >= 0 else {
            return .negativeAmount
        }
        guard let target = selected, let account = account else {
            return .empty
        }
        
        let transaction = LedgerEntry(
            name: target.name,
            credit: 0,
            debit: amount,
            date: date,
            location: target.location ?? "Bank",
            category: categories.bills.utility,
            account: account
        );
        
        modelContext.insert(transaction);
        
        if doStore {
            target.points.append(amount)
        }
        
        return nil;
    }
    
#if os(macOS)
    let minWidth: CGFloat = 90;
    let maxWidth: CGFloat = 100;
#else
    let minWidth: CGFloat = 110;
    let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        TransactionEditorFrame(.utilityPay, apply: apply, content: {
            Grid {
                GridRow {
                    Text("For Utility:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("Utility", selection: $selected) {
                        Text("Select One", comment: "Select One utility").tag(nil as Utility?)
                        ForEach(cache, id: \.id) { utility in
                            Text(utility.name).tag(utility)
                        }
                    }.labelsHidden()
                }
                
                Divider()
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(amount)
                }
                
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($account)
                        .namedPairPickerStyle(horizontalSizeClass == .compact ? .vertical : .horizontal)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        
                        Button("Today", action: { date = .now } )
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Save Datapoint:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Toggle("Save", isOn: $doStore)
                            .labelsHidden()
                        
                        TooltipButton("When this is on, Edmund will automatically record this transaction in the Utility's data points.")
                        
                        Spacer()
                    }
                }
            }.onAppear(perform: refresh)
        })
    }
}

#Preview {
    DebugContainerView {
        UtilityPayment()
    }
}
