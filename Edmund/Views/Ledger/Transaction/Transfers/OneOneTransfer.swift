//
//  OneOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

struct OneOneTransfer : View, TransactionEditorProtocol {
    init(_ signal: TransactionEditorSignal) {
        self.signal = signal
        self.signal.action = apply
    }
    
    var signal: TransactionEditorSignal;
    @Environment(\.categoriesContext) private var categories: CategoriesContext?;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @Environment(\.modelContext) private var modelContext;
    
    @State private var src: SubAccount?;
    @State private var dest: SubAccount?
    @State private var amount: Decimal = 0.0;
    @State private var date = Date.now;
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        guard let categories = categories else {
            warning.warning = .init(message: "noCategories", title: "Error")
            return false
        }
        guard src?.parent != nil &&  dest?.parent != nil && amount != 0.0 else {
            warning.warning = .init(message: "emptyFields", title: "Warning")
            return false
        }
        
        let trans: [LedgerEntry] = [
            .init(
                name: src!.name + " to " + dest!.name,
                credit: 0,
                debit: amount,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: src!
            ),
            .init(
                name: src!.name + " to " + dest!.name,
                credit: amount,
                debit: 0,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: dest!
            )
        ]
        
        for item in trans { modelContext.insert(item) }
        return true
    }
    
    var body: some View {
        VStack {
        
            Grid() {
                GridRow {
                    Text("Amount")
                    TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                }
                
                GridRow {
                    Text("From")
                    NamedPairPicker($src)
                }
                
                GridRow {
                    Text("Into")
                    NamedPairPicker($dest)
                }
                
                GridRow {
                    Text("Date")
                    DatePicker("Date", selection: $date, displayedComponents: .date).labelsHidden()
                }
                
            }.frame(minWidth: 300, maxWidth: .infinity)
        }
    }
}

#Preview {
    OneOneTransfer(.init()).modelContainer(Containers.debugContainer).padding()
}
