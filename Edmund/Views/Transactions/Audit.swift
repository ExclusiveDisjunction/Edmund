//
//  Audit.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI

@Observable
class AuditViewModel : TransViewBase {
    func compile_deltas() -> Dictionary<NamedPair, Decimal> {
        if (!validate())
        { return [:]; }
        
        return [ account : -amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        return [ LedgerEntry(memo: "Audit", credit: 0, debit: amount, date: Date.now, location: "Bank", category_pair: .init("Account Control", "Audit", kind: .category), account_pair: account) ];
    }
    func validate() -> Bool {
        var empty_ones: [String] = [];
        
        if account.parentEmpty { empty_ones.append("account") }
        if account.childEmpty { empty_ones.append("sub account") }
    
        if empty_ones.isEmpty { return true }
        else {
            err_msg = "The following fields are empty: \(empty_ones.joined(separator: ", "))"
            return false
        }
    }
    func clear() {
        amount = 0
        account = NamedPair(kind: .account)
        err_msg = nil
    }
    
    var amount: Decimal = 0;
    var account: NamedPair = NamedPair(kind: .account)
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
                NamedPairEditor(acc: $vm.account)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Audit(vm: AuditViewModel())
}
