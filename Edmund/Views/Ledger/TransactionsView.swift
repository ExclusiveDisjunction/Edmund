//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;
import EdmundCore;

enum TransactionKind : Identifiable, Hashable, Equatable {
    case simple,
         composite,
         grouped,
         creditCard
    case personalLoan,
         refund
    case income
    case billPay    (BillsKind),
         utilityPay
    case audit
    case transfer(TransferKind)
    
    var name: LocalizedStringKey {
        switch self {
            case .simple:          "Transaction"
            case .composite:       "Composite Transaction"
            case .grouped:         "Batch Transactions"
            case .creditCard:      "Credit Card Transactions"
            case .personalLoan:    "Personal Loan"
            case .refund:          "Refund"
            case .income:          "Income"
            case .billPay(let v):  v.name
            case .utilityPay:      "Utility"
            case .audit:           "Audit"
            case .transfer(let v): v.name
        }
    }
    
    var id: Self { self }
}

protocol TransactionEditorProtocol : View {
    func apply() -> Bool;
}

private struct CategoriesContextKey: EnvironmentKey {
    static let defaultValue: CategoriesContext? = nil
}

extension EnvironmentValues {
    public var categoriesContext: CategoriesContext? {
        get { self[CategoriesContextKey.self] }
        set { self[CategoriesContextKey.self] = newValue }
    }
}

struct TransactionEditorFrame<Content, WarningKind> : View where Content: View, WarningKind: WarningBasis {
    init(_ kind: TransactionKind, warning: BaseWarningManifest<WarningKind>, apply: @escaping () -> Bool, @ViewBuilder content: @escaping () -> Content) {
        self.kind = kind;
        self.apply = apply;
        self.warning = warning;
        self.content = content;
    }
    
    let kind: TransactionKind;
    private let apply: () -> Bool;
    private let content: () -> Content;
    @Bindable private var warning: BaseWarningManifest<WarningKind>;
    
    @Environment(\.dismiss) private var dismiss;
    
    private func submit() {
        if apply() {
            dismiss()
        }
    }
    private func cancel() {
        dismiss()
    }
    
    var body: some View {
        VStack {
            Text(kind.name).font(.title2)
            
            content()
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Cancel", action: cancel).buttonStyle(.bordered)
                Button("Save", action: submit).buttonStyle(.borderedProminent)
            }
        }.padding()
            .alert("Error", isPresented: $warning.isPresented, actions: {
                Button("Ok", action: { warning.isPresented = false } )
            }, message: {
                Text(warning.message ?? "internalError")
            })
    }
}

struct TransactionsEditor : View {
    let kind: TransactionKind;
    
    var body: some View {
        switch kind {
            case .simple:          SimpleTransaction()
            case .composite:       Text("Composite Transaction")
            case .grouped:         Text("Batch Transactions")
            case .creditCard:      Text("Credit Card Transactions")
            case .personalLoan:    PersonalLoan()
            case .refund:          Refund()
            case .income:          Text("Income")
            case .billPay(let v):  BillPayment(kind: v)
            case .utilityPay:      UtilityPayment()
            case .audit:           Audit()
            case .transfer(let v): Transfer(v)
        }
    }
}
