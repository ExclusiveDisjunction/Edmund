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
    enum Mode : LocalizedStringKey, Identifiable, CaseIterable {
        case loan = "Loan", repayment = "Repayment"
        
        var id: Self { self }
    }
    
    @State private var mode = Mode.loan;
    @State private var person: String = "";
    @State private var amount: Decimal = 0;
    @State private var date: Date = Date.now;
    @State private var account: SubAccount?;
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
        
        let name = switch mode {
            case .loan: "Personal loan to \(person)"
            case .repayment: "Repayment from \(person)"
        }
        
        let transaction = LedgerEntry(
            name: name,
            credit: mode == .loan ? 0 : amount,
            debit: mode == .loan ? amount : 0,
            date: date,
            location: "Bank",
            category: mode == .loan ? categories.payments.loan : categories.payments.repayment,
            account: destination
        );
        
        modelContext.insert(transaction);
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.personalLoan, warning: warning, apply: apply, content: {
            Grid {
                GridRow {
                    Text("Mode:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Picker("", selection: $mode) {
                        ForEach(Mode.allCases, id: \.id) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }.labelsHidden()
                        .pickerStyle(.segmented)
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", value: $amount, format: .currency(code: currencyCode))
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif

                }
                
                GridRow {
                    Text(mode == .loan ? "To:" : "From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Person", text: $person)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Account:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($account)
                }
            }
        })
    }
}

#Preview {
    PersonalLoan()
        .modelContainer(Containers.debugContainer)
}
