//
//  UtilityPayment.swift
//  Edmund
//
//  Created by Hollan on 4/21/25.
//

import SwiftUI
import SwiftData;

struct UtilityPayment : TransactionEditorProtocol {
    init(_ signal: TransactionEditorSignal) {
        self.signal = signal;
        self.signal.action = self.apply;
    }
    
    @Query private var utilities: [Utility];
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    var signal: TransactionEditorSignal;
    @State private var selected: Utility?;
    @State private var account: SubAccount?;
    @State private var amount: Decimal = 0.0;
    @State private var date: Date = .now;
    @State private var doStore: Bool = true;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    let minWidth: CGFloat = 90;
    let maxWidth: CGFloat = 100;
#else
    let minWidth: CGFloat = 110;
    let maxWidth: CGFloat = 120;
#endif
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        guard let target = selected, let account = account else {
            print("Aborting because the target \(selected == nil) or account \(account == nil) is nil ")
            warning.warning = .init(message: "Please fill in all fields", title: "Error");
            return false;
        }
        
        guard let categoriesContext = categoriesContext else {
            warning.warning = .init(message: "An internal error has occured. Please report this bug (Issue: missing categories context)", title: "Internal Error");
            return false;
        }
        
        guard amount >= 0 else {
            warning.warning = .init(message: "The amount cannot be negative", title: "Error");
            return false;
        }
        
        let transaction = LedgerEntry(
            name: target.name,
            credit: 0,
            debit: amount,
            date: date,
            location: target.location ?? "Bank",
            category: categoriesContext.bills.utility,
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
    
    var body: some View {
        Grid {
            GridRow {
                Text("For Utility:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                HStack {
                    Picker("Utility", selection: $selected) {
                        Text("Select One", comment: "Select One utility").tag(nil as Utility?)
                        ForEach(utilities, id: \.id) { utility in
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
        }.onChange(of: selected, { _, _ in
            print("the selected changed, is it nil? \(selected == nil)")
        }).onChange(of: account, { _, _ in
            print("the account changed, is it nil? \(account == nil)")
        })
    }
}

#Preview {
    UtilityPayment(.init()).padding().modelContainer(Containers.debugContainer)
}
