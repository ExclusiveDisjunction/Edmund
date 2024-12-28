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
    case payday(sub: PaydayViewModel)
    case creditCardTrans(sub: CreditCardTransViewModel)
    case one_one_transfer(sub: OneOneTransferVM)
    case one_many_transfer(sub: OneManyTransferVM)
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        switch self {
        case .manual(let sub): return sub.compile_deltas()
        case .generalIncome(let sub): return sub.compile_deltas()
        case .payment(let sub): return sub.compile_deltas()
        case .audit(let sub): return sub.compile_deltas()
        case .payday(let sub): return sub.compile_deltas()
        case .creditCardTrans(let sub): return sub.compile_deltas()
        case .one_one_transfer(let sub): return sub.compile_deltas()
        case .one_many_transfer(let sub): return sub.compile_deltas()
        }
    }
    func create_transactions() -> [LedgerEntry]? {
        switch self {
        case .manual(let sub): return sub.create_transactions()
        case .generalIncome(let sub): return sub.create_transactions()
        case .payment(let sub): return sub.create_transactions()
        case .audit(let sub): return sub.create_transactions()
        case .payday(let sub): return sub.create_transactions()
        case .creditCardTrans(let sub): return sub.create_transactions()
        case .one_one_transfer(let sub): return sub.create_transactions()
        case .one_many_transfer(let sub): return sub.create_transactions()
        }
    }
    func validate() -> Bool {
        switch self {
        case .manual(let sub): return sub.validate()
        case .generalIncome(let sub): return sub.validate()
        case .payment(let sub): return sub.validate()
        case .audit(let sub): return sub.validate()
        case .payday(let sub): return sub.validate()
        case .creditCardTrans(let sub): return sub.validate()
        case .one_one_transfer(let sub): return sub.validate()
        case .one_many_transfer(let sub): return sub.validate()
        }
    }
    
    func clear() {
        switch self {
        case .manual(let sub): sub.clear()
        case .generalIncome(let sub): sub.clear()
        case .payment(let sub): sub.clear()
        case .audit(let sub): sub.clear()
        case .payday(let sub): sub.clear()
        case .creditCardTrans(let sub): sub.clear()
        case .one_one_transfer(let sub): return sub.clear()
        case .one_many_transfer(let sub): return sub.clear()
        }
    }
}

struct TransactionsView : View {
    
    @State var sub_trans: [TransactionEnum] = [];
    @State var selected: UUID?;
    
    private func validate() {
        for transaction in sub_trans {
            let _ = transaction.validate()
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
                Text("Basic")
                Button("Manual Transactions", action: {
                    sub_trans.append(.manual(sub: ManualTransactionsViewModel()))
                } )
                Button("Payment", action: {
                    sub_trans.append(.payment(sub: PaymentViewModel()))
                })
                
                Divider()
                
                Text("Account Control")
                Button("General Income", action: {
                    sub_trans.append(.generalIncome(sub: GeneralIncomeViewModel()))
                }).help("Gift or Interest")
                Button("Payday", action: {
                    sub_trans.append(.payday(sub: PaydayViewModel()))
                }).help("Takes in a paycheck, and allows for easy control of moving money to specific accounts")
                Button(action: {
                    sub_trans.append(.audit(sub: AuditViewModel()))
                }) {
                    Text("Audit").foregroundStyle(Color.red)
                }
                
                Divider()
                
                Text("Grouped")
                Button("Credit Card Transactions", action: {
                    sub_trans.append(.creditCardTrans(sub: CreditCardTransViewModel()))
                }).help("Records transactions for a specific credit card, and automatically moves money in a specified account to a designated sub-account")
                
                Divider()
                
                Text("Transfer")
                Button("One-to-One", action: {
                    sub_trans.append(.one_one_transfer(sub: OneOneTransferVM()))
                })
                Button("One-to-Many", action: {
                    sub_trans.append(.one_many_transfer(sub: OneManyTransferVM()))
                })
                Button("Many-to-One", action: {}).disabled(true)
                Button("Many-to-Many", action: {}).disabled(true)
                
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
                    case .payday(let sub): Payday(vm: sub).padding(.bottom, 5)
                    case .creditCardTrans(let sub): CreditCardTrans(vm: sub).padding(.bottom, 5)
                    case .one_one_transfer(let sub): OneOneTransfer(vm: sub).padding(.bottom, 5)
                    case .one_many_transfer(let sub): OneManyTransfer(vm: sub).padding(.bottom, 5)
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
