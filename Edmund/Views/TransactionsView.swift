//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;

enum TransactionEnum : Identifiable {
    var id: UUID { UUID() }
    
    case manual(sub: ManualTransactionsViewModel)
    case generalIncome(sub: GeneralIncomeViewModel)
    case payment(sub: PaymentViewModel)
    case audit(sub: AuditViewModel)
    case payday
    case creditCardTrans
    case transfer
    
    func compile_deltas() -> Dictionary<String, Decimal> {
        switch self {
        case .manual(let sub): return sub.compile_deltas()
        case .generalIncome(let sub): return sub.compile_deltas()
        case .payment(let sub): return sub.compile_deltas()
        case .audit(let sub): return sub.compile_deltas()
        case .payday: break
        case .creditCardTrans: break
        case .transfer: break
        }
        
        return Dictionary<String, Decimal>();
    }
    func create_transactions() throws(TransactionError) -> [LedgerEntry] {
        switch self {
        case .manual(let sub): return try sub.create_transactions()
        case .generalIncome(let sub): return try sub.create_transactions()
        case .payment(let sub): return try sub.create_transactions()
        case .audit(let sub): return try sub.create_transactions()
        case .payday: break
        case .creditCardTrans: break
        case .transfer: break
        }
        
        return [];
    }
    @discardableResult
    func validate() -> Bool {
        switch self {
        case .manual(let sub): return sub.validate()
        case .generalIncome(let sub): return sub.validate()
        case .payment(let sub): return sub.validate()
        case .audit(let sub): return sub.validate()
        case .payday: break
        case .creditCardTrans: break
        case .transfer: break
        }
        
        return false;
    }
    
    func clear() {
        switch self {
        case .manual(let sub): sub.clear()
        case .generalIncome(let sub): sub.clear()
        case .payment(let sub): sub.clear()
        case .audit(let sub): sub.clear()
        case .payday: break
        case .creditCardTrans: break
        case .transfer: break
        }
    }
}

struct TransactionsView : View {
    
    @State var sub_trans: [TransactionEnum] = [];
    @State var selected: UUID?;
    
    private func validate() {
        for transaction in sub_trans {
            transaction.validate()
        }
    }
    private func clear_all() {
        for transaction in sub_trans {
            transaction.clear();
        }
    }
    
    var body : some View {
        HStack {
            Menu {
                Text("Simple")
                Button("Manual Transactions", action: {
                    sub_trans.append(.manual(sub: ManualTransactionsViewModel()))
                } )
                Button("General Income", action: {
                    sub_trans.append(.generalIncome(sub: GeneralIncomeViewModel()))
                }).help("Gift or Interest")
                Button("Payment", action: {
                    sub_trans.append(.payment(sub: PaymentViewModel()))
                })
                Button(action: {
                    sub_trans.append(.audit(sub: AuditViewModel()))
                }) {
                    Text("Audit").foregroundStyle(Color.red)
                }
                
                Divider()
                
                Text("Grouped")
                Button("Payday", action: {}).help("Takes in a paycheck, and allows for easy control of moving money to specific accounts")
                Button("Credit Card Transactions", action: {}).help("Records transactions for a specific credit card, and automatically moves money in a specified account to a designated sub-account")
                
                Divider()
                
                Menu {
                    Button("One-to-One", action: {})
                    Button("One-to-Many", action: {})
                    Button("Many-to-One", action: {})
                    Button("Many-to-Many", action: {})
                } label: {
                    Text("Transfer")
                }
                
            } label: {
                Label("Add", systemImage: "plus")
            }.help("Add a specific kind of transaction to the editor")
            
            Button(action: {
                validate()
            }) {
                Label("Validate", systemImage: "slider.horizontal.2.square")
            }.help("Determine if there are errors in any transaction")
            
            Button(action: {}) {
                Label("Enact", systemImage: "pencil")
            }.help("Apply these transactions to the system")
            
            Button(action: {
                clear_all()
            }) {
                Label("Clear", systemImage: "pencil.slash").foregroundStyle(.red)
            }
        }.padding([.leading, .trailing, .top]).padding(.bottom, 5)
        
        HStack {
            Text("Current Transactions").font(.title).padding([.leading, .trailing]).padding(.bottom, 5)
            Spacer()
        }
        
        
        ScrollView {
            ForEach(sub_trans) { trans in
                VStack {
                    switch trans {
                    case .manual(let sub): ManualTransactions(vm: sub).padding(.bottom, 5)
                    case .generalIncome(let sub): GeneralIncome(vm: sub).padding(.bottom, 5)
                    case .payment(let sub): Payment(vm: sub).padding(.bottom, 5)
                    case .audit(let sub): Audit(vm: sub).padding(.bottom, 5)
                    case .payday: Text("payday")
                    case .creditCardTrans: Text("credit card trans")
                    case .transfer: Text("Transfer")
                    }
                }
             }
        }.padding()
        Spacer()
    }
}

#Preview {
    TransactionsView()
}
