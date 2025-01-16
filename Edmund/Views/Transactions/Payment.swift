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

@Observable
class PaymentViewModel : TransViewBase {
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        if !validate() { return nil; }
        
        let sub_account: String;
        let amount: Decimal;
        
        switch payment_type {
        case .bill:
            sub_account = sub_account_name;
            amount = -self.amount;
        case .loan:
            sub_account = "Loan";
            amount = -self.amount;
        case .repayment:
            sub_account = "Loan";
            amount = self.amount;
        case .refund:
            sub_account = "Refund";
            amount = self.amount;
        }
        
        return [.init(self.account_name, sub_account): amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        let memo: String;
        let sub_tender: String;
        let sub_category: String;
        let credit: Decimal;
        let debit: Decimal;
        
        switch payment_type {
        case .bill:
            memo = reason;
            sub_tender = sub_account_name;
            sub_category = "Bill";
            credit = 0;
            debit = amount;
        case .loan:
            memo = "Loan to " + reason;
            sub_tender = "Loan";
            sub_category = "Loan";
            credit = 0;
            debit = amount;
        case .repayment:
            memo = "Repayment from " + reason;
            sub_tender = "Loan";
            sub_category = "Loan";
            credit = amount;
            debit = 0;
        case .refund:
            memo = "Refund for " + reason;
            sub_tender = "Refund";
            sub_category = "Refund";
            credit = amount;
            debit = 0;
        }
        
        return [
            .init(
                memo: memo,
                credit: credit,
                debit: debit,
                date: Date.now,
                location: "Bank",
                category: .init("Payment", sub_category),
                account: .init(account_name, sub_tender)
            )
        ]
    }
    func validate() -> Bool {
        var emptys: [String] = [];
        
        if account_name.isEmpty {
            emptys.append("account")
        }
        if sub_account_name.isEmpty && payment_type == .refund {
            emptys.append("sub account")
        }
        if reason.isEmpty {
            emptys.append("reason")
        }
        
        if emptys.isEmpty {
            err_msg = nil;
            return true;
        } else {
            err_msg = "The following fields are empty: " + emptys.joined(separator: ", ");
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
    
    
    var err_msg: String? = nil;
    var payment_type: PaymentType = .bill
    var account_name: String = "";
    var sub_account_name: String = "";
    var amount: Decimal = 0.00;
    var reason: String = "";
}

struct Payment: View {
    @Bindable var vm: PaymentViewModel;
    
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
