//
//  PersonLoan.swift
//  Edmund
//
//  Created by Hollan on 1/16/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct PersonalLoan: TransactionEditorProtocol {
    @State private var person: String = "";
    @State private var amount: Decimal = 0;
    @State private var date: Date = Date.now;
    @State private var account: SubAccount?;
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError")
            return false
        }
        
        guard let destination = account else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        guard !person.isEmpty else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
    
        guard amount >= 0 else {
            warning.warning = .init(message: "negativeAmount")
            return false;
        }
        
        let transaction = LedgerEntry(
            name: "Personal loan to \(person)",
            credit: 0,
            debit: amount,
            date: date,
            location: "Bank",
            category: categories.payments.loan,
            account: destination
        );
        
        modelContext.insert(transaction);
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.personalLoan, warning: warning, apply: apply, content: {
            VStack {
                HStack {
                    Text("I loaned")
                    TextField("Person", text: $person)
                    TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                }
                HStack {
                    Text("On")
                    DatePicker("On", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                    Text("from", comment: "on [date] from [account]")
                    NamedPairPicker($account)
                }
            }
        })
    }
}

#Preview {
    PersonalLoan()
        .padding()
        .modelContainer(Containers.debugContainer)
}
