//
//  Transactions.swift
//  Edmund
//
//  Created by Hollan on 12/23/24.
//

import SwiftUI
import SwiftData;

enum TransactionEnum {
    case manual(sub: ManualTransactionsViewModel = .init())
    case generalIncome(sub: GeneralIncomeViewModel = .init())
    case payment(sub: PaymentViewModel = .init())
    case audit(sub: AuditViewModel = .init())
    case payday(sub: PaydayViewModel = .init())
    case creditCardTrans(sub: CreditCardTransViewModel = .init())
    case one_one_transfer(sub: OneOneTransferVM = .init())
    case one_many_transfer(sub: OneManyTransferVM = .init())
    case many_one_transfer(sub: ManyOneTransferVM = .init())
    case many_many_transfer(sub: ManyManyTransferVM = .init())
    
    func as_trans_view_base() -> any TransViewBase {
        switch self {
        case .manual(let sub): return sub
        case .generalIncome(let sub): return sub
        case .payment(let sub): return sub
        case .audit(let sub): return sub
        case .payday(let sub): return sub
        case .creditCardTrans(let sub): return sub
        case .one_one_transfer(let sub): return sub
        case .one_many_transfer(let sub): return sub
        case .many_one_transfer(let sub): return sub
        case .many_many_transfer(let sub): return sub
        }
    }
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        return self.as_trans_view_base().compile_deltas()
    }
    func create_transactions() -> [LedgerEntry]? {
        return self.as_trans_view_base().create_transactions()
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
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        inner.compile_deltas()
    }
    func create_transactions() -> [LedgerEntry]? {
        inner.create_transactions()
    }
    func clear() {
        inner.clear()
    }
}
struct TransactionWrapper : View {
    @Bindable var vm: TransactionWrapperVM;
    
    var body: some View {
        HStack {
            VStack {
                Toggle("Selected", isOn: $vm.selected).labelsHidden()
            }
            VStack {
                switch vm.inner {
                case .manual(let sub): ManualTransactions(vm: sub)
                case .generalIncome(let sub): GeneralIncome(vm: sub)
                case .payment(let sub): Payment(vm: sub)
                case .audit(let sub): Audit(vm: sub)
                case .payday(let sub): Payday(vm: sub)
                case .creditCardTrans(let sub): CreditCardTrans(vm: sub)
                case .one_one_transfer(let sub): OneOneTransfer(vm: sub)
                case .one_many_transfer(let sub): OneManyTransfer(vm: sub)
                case .many_one_transfer(let sub): ManyOneTransfer(vm: sub)
                case .many_many_transfer(let sub): ManyManyTransfer(vm: sub).disabled(vm.selected)
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
    func remove_selected() {
        sub_trans.removeAll(where: { item in
            item.selected
        })
    }
}

struct TransactionsView : View {
    
    @Bindable var vm: TransactionsViewModel;
    @Environment(\.modelContext) private var context;
    @State var alert_msg: String = .init();
    @State var show_alert: Bool = false;
    @State var alert_is_err: Bool = true;
    
    private func validate() -> Bool {
        for transaction in vm.sub_trans {
            if !transaction.validate() { return false }
        }
        
        alert_msg = "All cells validated."
        alert_is_err = false;
        show_alert = true;
        return true
    }
    private func reset_all() {
        for transaction in vm.sub_trans {
            transaction.clear();
        }
    }
    private func clear_all() {
        vm.clear_all();
    }
    private func remove_selected() {
        vm.remove_selected();
    }
    private func enact() {
        if !self.validate() {
            alert_is_err = true;
            alert_msg = "One or more cells have errors, please resolve them and try again.";
            show_alert = true;
            return;
        }
        
        for (i, item) in vm.sub_trans.enumerated() {
            if let list = item.create_transactions() {
                for transaction in list {
                    context.insert(transaction);
                }
            }
            else {
                alert_is_err = true;
                alert_msg = "Unexpected result from cell \(i)."
                show_alert = true;
                return;
            }
        }
        
        clear_all();
        alert_is_err = false;
        alert_msg = "Enacted successfully";
        show_alert = true;
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
                    Button("Payment", action: {
                        vm.sub_trans.append(.init(.payment()))
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
                    let _ = validate()
                }) {
                    Label("Validate", systemImage: "slider.horizontal.2.square")
                }.help("Determine if there are errors in any transaction")
                
                Button(action: enact) {
                    Label("Enact", systemImage: "pencil")
                }.help("Apply these transactions to the system")
                
            }.padding([.leading, .trailing]).padding(.bottom, 5)
            
            HStack {
                Button(action: reset_all) {
                    Label("Reset Cells", systemImage: "pencil.slash").foregroundStyle(.red)
                }
                Button(action: {
                    withAnimation{
                        self.remove_selected()
                    }
                }) {
                    Label("Remove Selected Cells", systemImage: "trash").foregroundStyle(.red)
                }
                Button(action: {
                    withAnimation {
                        self.clear_all()
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
        }.alert(alert_is_err ? "Validation Errors" : "Notice", isPresented: $show_alert, actions: {
            Button("Ok", action: {
                show_alert = false;
            })
        }, message: {
            Text(alert_msg)
        })
    }
}

#Preview {
    TransactionsView(vm: TransactionsViewModel())
}
