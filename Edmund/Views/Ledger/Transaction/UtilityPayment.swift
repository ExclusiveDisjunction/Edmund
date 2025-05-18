//
//  UtilityPayment.swift
//  Edmund
//
//  Created by Hollan on 4/21/25.
//

import SwiftUI
import SwiftData;
import EdmundCore;

struct UtilityPayment : TransactionEditorProtocol {
    @Query private var utilities: [Utility];
    @Environment(\.categoriesContext) private var categoriesContext;
    @Environment(\.modelContext) private var modelContext;
    
    @State private var selected: Utility?;
    @State private var account: SubAccount?;
    @State private var amount: Decimal = 0.0;
    @State private var date: Date = .now;
    @State private var doStore: Bool = true;
    @State private var cache: [Utility] = [];
    private var warning = StringWarningManifest();
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func refresh() {
        cache = utilities.filter { !$0.isExpired }.sorted(by: { $0.name < $1.name } )
    }
    
    func apply() -> Bool {
        guard let target = selected, let account = account else {
            print("Aborting because the target \(selected == nil) or account \(account == nil) is nil ")
            warning.warning = .init(message: "Please fill in all fields");
            return false;
        }
        
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError");
            return false;
        }
        
        guard amount >= 0 else {
            warning.warning = .init(message: "The amount cannot be negative");
            return false;
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
            let entry = UtilityEntry(date, amount);
            entry.parent = target;
            
            modelContext.insert(entry);
        }
        
        return true;
    }
    
#if os(macOS)
    let minWidth: CGFloat = 90;
    let maxWidth: CGFloat = 100;
#else
    let minWidth: CGFloat = 110;
    let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        TransactionEditorFrame(.utilityPay, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("For Utility:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Picker("Utility", selection: $selected) {
                            Text("Select One", comment: "Select One utility").tag(nil as Utility?)
                            ForEach(cache, id: \.id) { utility in
                                Text(utility.name).tag(utility)
                            }
                        }.labelsHidden()
                        Spacer()
                    }
                }
                Divider()
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                            .textFieldStyle(.roundedBorder)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif

                        
                        Spacer()
                    }
                }
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        NamedPairPicker($account)
                        
                        Spacer()
                    }
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
                        
                        Spacer()
                    }
                }
            }.onAppear(perform: refresh)
        })
    }
}

#Preview {
    UtilityPayment().padding().modelContainer(Containers.debugContainer)
}
