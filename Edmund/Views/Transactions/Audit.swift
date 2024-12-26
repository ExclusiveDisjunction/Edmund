//
//  Audit.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI

class AuditViewModel : ObservableObject, TransViewBase {
    func compile_deltas() -> Dictionary<String, Decimal> {
        if (!validate())
        { return [:]; }
        
        return [ account + "." + sub_account : -amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        return [ LedgerEntry(id: UUID(), memo: "Audit", credit: 0, debit: amount, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Audit", tender: account, sub_tender: sub_account) ];
    }
    func validate() -> Bool {
        var empty_ones: [String] = [];
        
        if account.isEmpty { empty_ones.append("account") }
        if sub_account.isEmpty { empty_ones.append("sub account") }
    
        if empty_ones.isEmpty { return true }
        else {
            err_msg = "The following fields are empty: \(empty_ones.joined(separator: ", "))"
            return false
        }
    }
    func clear() {
        amount = 0
        account = ""
        sub_account = ""
        err_msg = nil
    }
    
    @Published var amount: Decimal = 0;
    @Published var account: String = "";
    @Published var sub_account: String = "";
    @Published var err_msg: String? = nil
    
    var id: UUID = UUID();
}

struct Audit: View {
    @ObservedObject var vm: AuditViewModel;
    
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
                TextField("Account", text: $vm.account)
                TextField("Sub Account", text: $vm.sub_account)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Audit(vm: AuditViewModel())
}
