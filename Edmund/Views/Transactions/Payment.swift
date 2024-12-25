//
//  Payment.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI

enum PaymentType {
    case refund
    case repayment
    case bill
    case loan
}

class PaymentViewModel : TransViewBase, ObservableObject {
    func compile_deltas() -> Dictionary<String, Decimal> {
        return Dictionary<String, Decimal>();
    }
    func create_transactions() throws(TransactionError) -> [LedgerEntry] {
        return [];
    }
    func validate() -> Bool {
        do {
            let _ = try create_transactions();
            return true
        } catch let e {
            err_msg = e.localizedDescription;
            return false;
        }
    }
    func clear() {
        err_msg = nil;
        payment_type = .bill
        account_name = ""
        sub_account_name = ""
        amount = 0
        reason = ""
    }
    
    
    @Published var err_msg: String? = nil;
    @Published var payment_type: PaymentType = .bill
    @Published var account_name: String = "";
    @Published var sub_account_name: String = "";
    @Published var amount: Double = 0.00;
    @Published var reason: String = "";
}

struct Payment: View {
    var id: UUID = UUID();
    
    @ObservedObject var vm: PaymentViewModel;
    
    var body: some View {
        VStack {
            HStack {
                Text("Payment").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundColor(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Picker("Kind:", selection: $vm.payment_type) {
                Text("Refund").tag(PaymentType.refund)
                Text("Repayment").tag(PaymentType.repayment)
                Text("Bill").tag(PaymentType.bill)
                Text("Loan").tag(PaymentType.loan)
            }
            
            HStack {
                Text("Regarding the amount of")
                TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                
                
                switch vm.payment_type {
                case .refund: Text("for")
                case .repayment: Text("from")
                case .bill: Text("for the service")
                case .loan: Text("to")
                }
                
                switch vm.payment_type {
                case .refund: TextField("Item", text: $vm.reason)
                case .repayment: TextField("Person", text: $vm.reason)
                case .bill: TextField("Service Name", text: $vm.reason)
                case .loan: TextField("Person", text: $vm.reason)
                }
            }
            
            HStack {
                switch vm.payment_type {
                case .bill, .loan: Text("From:")
                case .refund, .repayment: Text("To:")
                }
                TextField("Account", text: $vm.account_name)
                switch vm.payment_type {
                case .bill: TextField("Sub Account", text: $vm.reason)
                case .loan, .repayment: TextField("Sub Account", text: Binding<String>(
                    get: {
                        "Hold"
                    },
                    set: { v in
                        return
                    }
                )).disabled(true)
                
                case .refund: TextField("Sub Account", text: $vm.sub_account_name)
                }
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Payment(vm: PaymentViewModel())
}
