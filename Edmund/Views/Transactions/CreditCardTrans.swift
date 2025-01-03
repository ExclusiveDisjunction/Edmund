//
//  CreditCardTrans.swift
//  Edmund
//
//  Created by Hollan on 12/26/24.
//

import SwiftUI

@Observable
class CreditCardTransViewModel : TransViewBase {
    init() {
        sub_transactions = ManualTransactionsViewModel(show_account: false)
    }
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        return nil;
    }
    func create_transactions() -> [LedgerEntry]? {
        //Keep in mind that I have to fill in the account, manual transactions will not do it for me.
        return nil;
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
    
        if account.isEmpty {
            empty_fields.append("account")
        }
        if target_account.isEmpty {
            empty_fields.append("target account")
        }
        if target_sub_account.isEmpty {
            empty_fields.append("target sub account")
        }
        
        let sub_good: Bool = sub_transactions?.validate() ?? true;
        
        if empty_fields.isEmpty && sub_good {
            err_msg = nil;
            return true;
        }
        else if empty_fields.isEmpty && !sub_good {
            err_msg = "Manual transactions failed";
            return false;
        }
        else if !empty_fields.isEmpty && sub_good {
            err_msg = "The following fields are empty: " + empty_fields.joined(separator: ", ")
            return false;
        }
        else {
            err_msg = "Manual transactions failed and the following fields are empty: " + empty_fields.joined(separator: ", ")
            return false;
        }
    }
    func clear() {
        account = "";
        target_account = "";
        target_sub_account = "Credit Card";
        sub_transactions?.clear()
        err_msg = nil
    }
    
    var account: String = "";
    var target_account: String = "";
    var target_sub_account: String = "Credit Card";
    var sub_transactions: ManualTransactionsViewModel? = nil;
    var err_msg: String? = nil;
}

struct CreditCardTrans: View {
    
    @Bindable var vm: CreditCardTransViewModel;
    
    var body: some View {
        VStack {
            HStack {
                Text("Credit Card Transactions").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundColor(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            HStack {
                Text("For credit account:")
                TextField("Account", text: $vm.account)
            }
            
            HStack {
                Spacer()
            }
            
            if let mtvm = vm.sub_transactions {
                ManualTransactions(vm: mtvm).padding(.bottom, 5)
            }
            
            HStack {
                Text("Balance transfer from")
                TextField("Target Account", text: $vm.target_account)
                TextField("Target Sub Account", text: $vm.target_sub_account)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    CreditCardTrans(vm: CreditCardTransViewModel())
}
