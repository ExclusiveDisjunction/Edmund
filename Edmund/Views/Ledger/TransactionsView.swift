//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;

enum TransactionKind : Identifiable, Equatable, Hashable {
    case simple, composite, grouped, creditCard
    case personalLoan, refund
    case income
    case billPay(BillsKind)
    case audit
    case transfer(TransferKind)
    
    var name: LocalizedStringKey {
        switch self {
            case .simple: "Transaction"
            case .composite: "Composite Transaction"
            case .grouped: "Batch Transactions"
            case .creditCard: "Credit Card Transactions"
            case .personalLoan: "Personal Loan"
            case .refund: "Refund"
            case .income: "Income"
            case .billPay(let v): v.name
            case .audit: "Audit"
            case .transfer(let v): v.name
        }
    }
    
    var id: Self { self }
}

protocol TransactionEditorProtocol : View {
    var signal: TransactionEditorSignal { get set }
    func apply(_ warning: StringWarningManifest) -> Bool;
}

@Observable
class TransactionEditorSignal {
    init() {
        self.action = nil
    }
    
    var action: ((StringWarningManifest) -> Bool)?;
    func submit(_ warning: StringWarningManifest) -> Bool? {
        guard let action = action else { return nil }
        
        return action(warning)
    }
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

struct TransactionEditor : View {
    let kind: TransactionKind
    @Bindable private var warning: StringWarningManifest = .init()
    @Bindable private var signal: TransactionEditorSignal = .init()
    @Environment(\.dismiss) private var dismiss;
    
    private func submit() {
        guard let result = signal.submit(warning) else {
            warning.warning = .init(message: "noInformationToSave", title: "Unexpected Error")
            return
        }
        
        if result {
            dismiss()
        }
    }
    private func cancel() {
        dismiss()
    }
    
    @ViewBuilder
    private var transactionBody: some View {
        switch kind {
            case .simple:          Text("Transaction")
            case .composite:       Text("Composite Transaction")
            case .grouped:         Text("Batch Transactions")
            case .creditCard:      Text("Credit Card Transactions")
            case .personalLoan:    Text("Personal Loan")
            case .refund:          Text("Refund")
            case .income:          Text("Income")
            case .billPay(let v):
                switch v {
                    case .utility: UtilityPayment(signal)
                    default:       BillPayment(signal, kind: v)
                }
            
            case .audit:           Text("Audit")
            case .transfer(let v): Transfer(signal, kind: v)
        }
    }
    
    var body: some View {
        VStack {
            Text(kind.name).font(.title2)
            
            transactionBody
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Cancel", action: cancel).buttonStyle(.bordered)
                Button("Save", action: submit).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}
