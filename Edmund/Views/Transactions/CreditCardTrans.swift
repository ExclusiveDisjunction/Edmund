//
//  CreditCardTrans.swift
//  Edmund
//
//  Created by Hollan on 12/26/24.
//

import SwiftUI

@Observable
class CreditCardTransViewModel : TransViewBase {
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        return nil;
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        //Keep in mind that I have to fill in the account, manual transactions will not do it for me.
        return nil;
    }
    func validate() -> Bool {
        var empty_fields: [String] = [];
    
        if account.isEmpty {
            empty_fields.append("account")
        }
        if target_account == nil {
            empty_fields.append("target account")
        }
        
        let sub_good: Bool = sub_transactions.validate();
        
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
        target_account = nil;
        sub_transactions.clear()
        err_msg = nil
    }
    
    var account: String = "";
    var target_account: SubAccount? = nil
    var sub_transactions: ManualTransactionsVM = .init()
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
            
            ManualTransactions(vm: vm.sub_transactions).padding(.bottom, 5)
            
            HStack {
                Text("Balance transfer from")
                NamedPairPicker(target: $vm.target_account, child_default: "Credit Card")
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    CreditCardTrans(vm: CreditCardTransViewModel())
}
