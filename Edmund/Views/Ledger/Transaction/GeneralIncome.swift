//
//  GeneralIncome.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI
import EdmundCore

enum IncomeKind : LocalizedStringKey, CaseIterable, Identifiable {
    case gift = "gifted"
    case pay = "paid"
    case repay = "repaid"
    
    var id: Self { self }
}

struct Income: TransactionEditorProtocol {
    @State private var kind: IncomeKind = .pay;
    @State private var person: String = "";
    @State private var amount: Decimal = 0;
    @State private var date: Date = .now;
    @State private var account: SubAccount? = nil;
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
        
        guard amount > 0 else {
            warning.warning = .init(message: "negativeAmount")
            return false;
        }
        
        guard !person.isEmpty  else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        let name = switch kind {
            case .gift: "Gift from \(person)"
            case .pay: "Pay"
            case .repay: "Repayment from \(person)"
        }
        
        let company = switch kind {
            case .gift: "Bank"
            case .repay: "Bank"
            case .pay: person
        }
        
        let category = switch kind {
            case .gift: categories.payments.gift
            case .pay: categories.accountControl.pay
            case .repay: categories.payments.repayment
        }
        
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
        
        return true;
    }

    var body: some View {
        TransactionEditorFrame(.income, warning: warning, apply: apply, content: {
            VStack {
                HStack {
                    Text("I got")
                    Picker("", selection: $kind) {
                        ForEach(IncomeKind.allCases, id: \.id) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }.labelsHidden()
                    TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                    Text("from")
                    TextField(kind == .pay ? "Company" : "Person", text: $person)
                    
                }
                HStack {
                    Text("On")
                    DatePicker("Date", selection: $date, displayedComponents: .date).labelsHidden()
                    Text("Deposit into:")
                    NamedPairPicker($account)
                }
            }
        })
    }
}

#Preview {
    Income()
        .padding()
        .modelContainer(Containers.debugContainer)
}
