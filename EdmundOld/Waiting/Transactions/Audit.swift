//
//  Audit.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI

@Observable
class AuditViewModel : TransViewBase {
    func compile_deltas() -> Dictionary<AccountPair, Decimal>? {
        if (!validate())
        { return nil; }
        
        return [ account : -amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        return [
            LedgerEntry(
                memo: "Audit",
                credit: 0,
                debit: amount,
                date: Date.now,
                location: "Bank",
                category: .init("Account Control", "Audit"),
                account: account)
        ];
    }
    func validate() -> Bool {
        if account.isEmpty {
            err_msg = "Account is empty"
            return false;
        }
        else {
            err_msg = nil;
            return true;
        }
    }
    func clear() {
        amount = 0
        account = .init()
        err_msg = nil
    }
    
    var amount: Decimal = 0;
    var account: AccountPair = .init()
    var err_msg: String? = nil
    var id: UUID = UUID();
}

struct Audit: View {
    @Bindable var vm: AuditViewModel;
    
    var body: some View {
        VStack {
            HStack {
                Text("Audit").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            HStack {
                Text("Deduct")
                TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                Text("from")
                AccountNameEditor(account: $vm.account)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Audit(vm: AuditViewModel())
}
