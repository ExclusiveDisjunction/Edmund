//
//  Audit.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI

@Observable
class AuditViewModel : TransactionEditor {
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        guard let acc = self.account else { return nil }
        
        if (!validate())
        { return nil; }
        
        return [ acc.id : -amount];
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil }
        
        guard let acc = self.account else { return nil }
        
        return [
            LedgerEntry(
                memo: "Audit",
                credit: 0,
                debit: amount,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.audit,
                account: acc)
        ];
    }
    func validate() -> Bool {
        if self.account == nil {
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
        account = nil
        err_msg = nil
    }
    
    var amount: Decimal = 0
    var account: SubAccount? = nil
    var err_msg: String? = nil
    var id: UUID = UUID()
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
                NamedPairPicker(target: $vm.account)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    Audit(vm: AuditViewModel())
}
