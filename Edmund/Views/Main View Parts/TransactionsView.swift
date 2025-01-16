//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;

enum TransactionEnum {
    case manual(sub: ManualTransactionsVM = .init())
    case generalIncome(sub: GeneralIncomeViewModel = .init())
    case bill_pay(sub: BillPaymentVM = .init())
    case personal_loan(sub: PersonalLoanTransVM = .init())
    case audit(sub: AuditViewModel = .init())
    case payday(sub: PaydayViewModel = .init())
    case creditCardTrans(sub: CreditCardTransViewModel = .init())
    case one_one_transfer(sub: OneOneTransferVM = .init())
    case one_many_transfer(sub: OneManyTransferVM = .init())
    case many_one_transfer(sub: ManyOneTransferVM = .init())
    case many_many_transfer(sub: ManyManyTransferVM = .init())
    case composite(sub: CompositeTransactionVM = .init())
    
    func as_trans_view_base() -> any TransViewBase {
        switch self {
        case .manual(let sub): return sub
        case .generalIncome(let sub): return sub
        case .bill_pay(let sub): return sub
        case .personal_loan(let sub): return sub
        case .audit(let sub): return sub
        case .payday(let sub): return sub
        case .creditCardTrans(let sub): return sub
        case .one_one_transfer(let sub): return sub
        case .one_many_transfer(let sub): return sub
        case .many_one_transfer(let sub): return sub
        case .many_many_transfer(let sub): return sub
        case .composite(let sub): return sub
        }
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        return self.as_trans_view_base().compile_deltas()
    }
    func create_transactions(_ cat: CategoriesContext) -> [LedgerEntry]? {
        return self.as_trans_view_base().create_transactions(cat)
    }
    func validate() -> Bool {
        return self.as_trans_view_base().validate()
    }
    func clear() {
        self.as_trans_view_base().clear()
    }
}

@Observable
class TransactionWrapperVM : Identifiable, TransViewBase {
    init(_ inner: TransactionEnum) {
        self.inner = inner;
    }
    
    var id: UUID = UUID()
    
    var selected: Bool = false;
    var inner: TransactionEnum;
    
    func validate() -> Bool {
        inner.validate()
    }
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        inner.compile_deltas()
    }
    func create_transactions(_ cat: CategoriesContext) -> [LedgerEntry]? {
        inner.create_transactions(cat)
    }
    func clear() {
        inner.clear()
    }
}
struct TransactionWrapper : View {
    @Bindable var vm: TransactionWrapperVM;
    
    var body: some View {
        HStack {
            Toggle("Selected", isOn: $vm.selected).labelsHidden()
            VStack {
                switch vm.inner {
                case .manual(let sub): ManualTransactions(vm: sub)
                case .generalIncome(let sub): GeneralIncome(vm: sub)
                case .bill_pay(let sub): BillPayment(vm: sub)
                case .personal_loan(let sub): PersonalLoanTrans(vm: sub)
                case .audit(let sub): Audit(vm: sub)
                case .payday(let sub): Payday(vm: sub)
                case .creditCardTrans(let sub): CreditCardTrans(vm: sub)
                case .one_one_transfer(let sub): OneOneTransfer(vm: sub)
                case .one_many_transfer(let sub): OneManyTransfer(vm: sub)
                case .many_one_transfer(let sub): ManyOneTransfer(vm: sub)
                case .many_many_transfer(let sub): ManyManyTransfer(vm: sub)
                case .composite(let sub): CompositeTransaction(vm: sub)
                }
            }.disabled(vm.selected).background(vm.selected ? Color.accentColor.opacity(0.2) : Color.clear)
        }.padding(.bottom, 5)
    }
}

@Observable
class TransactionsViewModel {
    var sub_trans: [TransactionWrapperVM] = [];
    
    func clear_all() {
        sub_trans = [];
    }
    func reset_all() {
        sub_trans.forEach( { $0.clear() })
    }
    func remove_selected() {
        sub_trans.removeAll(where: { item in
            item.selected
        })
    }
    
    func validate(alert: inout AlertContext, okShowAlert: Bool = true) -> Bool {
        var result: Bool = true;
        for transaction in sub_trans {
            if !transaction.validate() {
                result = false
            }
        }
        
        if result {
            if okShowAlert {
                alert = .init("All cells validated", is_error: false)
            }
            return true
        }
        else {
            alert = .init("One or more cells did not validate. Please correct errors & try again.", is_error: true)
            return true
        }
    }

}

struct TransactionsView : View {
    @Bindable var vm: TransactionsViewModel;
    
    @Environment(\.modelContext) private var context;
    @Query var categories: [SubCategory];
    @State var alert_context: AlertContext = .init();
    
    private func enact() {
        if !vm.validate(alert: &alert_context, okShowAlert: false) {
            return;
        }
        
        let cats = CategoriesContext(from: categories, context: self.context)
        
        for (i, item) in vm.sub_trans.enumerated() {
            if let list = item.create_transactions(cats) {
                for transaction in list {
                    context.insert(transaction);
                }
            }
            else {
                alert_context = .init("Unexpected null result from cell \(i)")
                return;
            }
        }
        
        vm.clear_all();
        alert_context = .init("Enacted successfully", is_error: false)
    }
    
    var body : some View {
        VStack {
            HStack {
                Text("Current Transactions").font(.title)
                Spacer()
            }.padding([.top, .leading, .trailing]).padding(.bottom, 5)
            
            HStack {
                Menu {
                    Text("Basic")
                    Button("Manual Transactions", action: {
                        vm.sub_trans.append(.init(.manual()))
                    } )
                    Button("Composite Transaction", action: {
                        vm.sub_trans.append( .init( .composite() ) )
                    })
                    Button("Bill Payment", action: {
                        vm.sub_trans.append(.init(.bill_pay()))
                    })
                    Button("Personal Loan", action: {
                        vm.sub_trans.append(.init(.personal_loan()))
                    })
                    
                    Divider()
                    
                    Text("Account Control")
                    Button("General Income", action: {
                        vm.sub_trans.append(.init(.generalIncome()))
                    }).help("Gift or Interest")
                    Button("Payday", action: {
                        vm.sub_trans.append( .init( .payday() ) )
                    }).help("Takes in a paycheck, and allows for easy control of moving money to specific accounts")
                    Button(action: {
                        vm.sub_trans.append(.init(.audit()))
                    }) {
                        Text("Audit").foregroundStyle(Color.red)
                    }
                    
                    Divider()
                    
                    Text("Grouped")
                    Button("Credit Card Transactions", action: {
                        vm.sub_trans.append( .init( .creditCardTrans() ) )
                    }).help("Records transactions for a specific credit card, and automatically moves money in a specified account to a designated sub-account")
                    
                    Divider()
                    
                    Text("Transfer")
                    Button("One-to-One", action: {
                        vm.sub_trans.append( .init( .one_one_transfer() ) )
                    })
                    Button("One-to-Many", action: {
                        vm.sub_trans.append( .init( .one_many_transfer() ) )
                    })
                    Button("Many-to-One", action: {
                        vm.sub_trans.append( .init( .many_one_transfer() ) )
                    })
                    Button("Many-to-Many", action: {
                        vm.sub_trans.append( .init( .many_many_transfer() ) )
                    })
                    
                } label: {
                    Label("Add", systemImage: "plus")
                }.help("Add a specific kind of transaction to the editor")
                
                Button(action: {
                    let _ = vm.validate(alert: &alert_context)
                }) {
                    Label("Validate", systemImage: "slider.horizontal.2.square")
                }.help("Determine if there are errors in any transaction")
                
                Button(action: enact) {
                    Label("Enact", systemImage: "pencil")
                }.help("Apply these transactions to the system")
                
            }.padding([.leading, .trailing]).padding(.bottom, 5)
            
            HStack {
                Button(action: vm.reset_all) {
                    Label("Reset Cells", systemImage: "pencil.slash").foregroundStyle(.red)
                }
                Button(action: {
                    withAnimation{
                        vm.remove_selected()
                    }
                }) {
                    Label("Remove Selected Cells", systemImage: "trash").foregroundStyle(.red)
                }
                Button(action: {
                    withAnimation {
                        vm.clear_all()
                    }
                }) {
                    Label("Remove All Cells", systemImage: "trash").foregroundStyle(.red)
                }
            }.padding([.leading, .trailing]).padding(.bottom, 5)
            
            ScrollView {
                VStack {
                    ForEach(vm.sub_trans) { vm in
                        TransactionWrapper(vm: vm)
                    }
                }
            }.padding()
        }.alert(alert_context.is_error ? "Validation Errors" : "Notice", isPresented: $alert_context.show_alert, actions: {
            Button("Ok", action: {
                alert_context.show_alert = false;
            })
        }, message: {
            Text(alert_context.message)
        })
    }
}

#Preview {
    TransactionsView(vm: TransactionsViewModel())
}
