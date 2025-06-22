//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;
import EdmundCore;

enum TransactionKind : Identifiable, Hashable, Equatable, Codable {
    case simple,
         composite,
         creditCard
    case personalLoan,
         refund
    case miscIncome,
         payday
    case billPay    (BillsKind),
         utilityPay
    case audit
    case transfer   (TransferKind)
    
#if os(macOS)
    case grouped
#endif
    
    var name: LocalizedStringKey {
        switch self {
            case .simple:          "Transaction"
            case .composite:       "Composite Transaction"
#if os(macOS)
            case .grouped:         "Batch Transactions"
#endif
            case .creditCard:      "Credit Card Transactions"
            case .personalLoan:    "Personal Loan"
            case .refund:          "Refund"
            case .miscIncome:      "Miscellaneous Income"
            case .payday:          "Payday"
            case .billPay(let v):  v.name
            case .utilityPay:      "Utility"
            case .audit:           "Audit"
            case .transfer(let v): v.name
        }
    }
    
    var id: Self { self }
}

protocol TransactionEditorProtocol : View {
    func apply() -> [ValidationFailure]?;
}

struct TransactionEditorFrame<Content, WarningKind> : View where Content: View, WarningKind: WarningBasis {
    init(_ kind: TransactionKind, warning: ValidationWarningManifest, apply: @escaping () -> [ValidationFailure]?, @ViewBuilder content: @escaping () -> Content) {
        self.kind = kind;
        self.apply = apply;
        self.warning = warning;
        self.content = content;
    }
    
    let kind: TransactionKind;
    private let apply: () -> [ValidationFailure]?;
    private let content: () -> Content;
    @Bindable private var warning: ValidationWarningManifest;
    
    @Environment(\.dismiss) private var dismiss;
    
    private func submit() {
        if let error = apply() {
            warning.warning = .init(error)
        }
        else {
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
                warning.content
            })
    }
}

struct TransactionsEditor : View {
    let kind: TransactionKind;
    
    var body: some View {
        switch kind {
            case .simple:          SimpleTransaction()
            case .composite:       CompositeTransaction()
#if os(macOS)
            case .grouped:         BatchTransactions()
#endif
            case .creditCard:      CreditCardTrans()
            case .personalLoan:    PersonalLoan()
            case .refund:          Refund()
            case .miscIncome:      MiscIncome()
            case .payday:          PaydayEditor()
            case .billPay(let v):  BillPayment(kind: v)
            case .utilityPay:      UtilityPayment()
            case .audit:           Audit()
            case .transfer(let v): Transfer(v)
        }
    }
}
