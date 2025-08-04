//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;
import EdmundCore

extension ValidationFailure : WarningBasis {
    public var message: LocalizedStringKey {
        self.display
    }
}

enum TransactionKind : Identifiable, Hashable, Equatable, Codable, Displayable {
    case simple,
         composite,
         creditCard
    case personalLoan,
         refund
    case miscIncome,
         payday,
         initialBalance
    case billPay    (StrictBillsKind),
         utilityPay
    case balanceCorrection
    case transfer   (TransferKind)
    
#if os(macOS)
    case grouped
#endif
    
    var display: LocalizedStringKey {
        switch self {
            case .simple:            "Transaction"
            case .composite:         "Composite Transaction"
#if os(macOS)
            case .grouped:           "Batch Transactions"
#endif
            case .creditCard:        "Credit Card Transactions"
            case .personalLoan:      "Personal Loan"
            case .refund:            "Refund"
            case .miscIncome:        "Miscellaneous Income"
            case .payday:            "Payday"
            case .billPay(let v):    v.display
            case .utilityPay:        "Utility"
            case .balanceCorrection: "Balance Correction"
            case .transfer(let v):   v.display
            case .initialBalance:    "Initial Balance"
        }
    }
    
    var title: LocalizedStringKey {
        switch self {
            case .simple:            "Simple Transaction"
            case .composite:         "Composite Transaction"
#if os(macOS)
            case .grouped:           "Batch Transactions"
#endif
            case .creditCard:        "Credit Card Transactions"
            case .personalLoan:      "Personal Loan"
            case .refund:            "Refund"
            case .miscIncome:        "Miscellaneous Income"
            case .payday:            "Payday"
            case .billPay(let v):    v.title
            case .utilityPay:        "Utility Payment"
            case .balanceCorrection: "Balance Correction"
            case .transfer(let v):   v.title
            case .initialBalance:    "Initial Balance"
        }
    }
    
    var id: Self { self }
}

protocol TransactionEditorProtocol : View {
    func apply() -> ValidationFailure?
}

struct TransactionEditorFrame<Content> : View where Content: View {
    init(_ kind: TransactionKind, apply: @escaping () async -> ValidationFailure?, @ViewBuilder content: @escaping () -> Content) {
        self.kind = kind;
        self.apply = apply;
        self.warning = .init();
        self.content = content;
    }
    
    let kind: TransactionKind;
    private let apply: () async -> ValidationFailure?;
    private let content: () -> Content;
    @Bindable private var warning: WarningManifest<ValidationFailure>;
    
    @Environment(\.dismiss) private var dismiss;
    
    @MainActor
    private func submit() {
        Task {
            if let error = await apply() {
                warning.warning = error
            }
            else {
                dismiss()
            }
        }
    }
    private func cancel() {
        dismiss()
    }
    
    var body: some View {
        VStack {
            Text(kind.title)
                .font(.title2)
            
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
                Text(warning.warning?.display ?? "internalError")
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
            case .balanceCorrection:           BalanceCorrection()
            case .transfer(let v): Transfer(v)
            case .initialBalance:   InitialBalance()
        }
    }
}
