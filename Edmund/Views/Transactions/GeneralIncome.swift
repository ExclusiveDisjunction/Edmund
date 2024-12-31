//
//  GeneralIncome.swift
//  Edmund
//
//  Created by Hollan on 12/24/24.
//

import SwiftUI

public enum GeneralIncomeKind {
    case gift
    case interest
}

@Observable
class GeneralIncomeViewModel : TransViewBase {
    var id: UUID = UUID()
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        if !validate() {
            return [:];
        }
        
        return [ account : amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil}
        
        switch kind {
        case .gift: return [ LedgerEntry(memo: "Gift from " + merchant, credit: amount, debit: 0, date: Date.now, location: "Bank", category_pair: .init("Account Control", "Gift", kind: .category), account_pair: account) ]
            
        case .interest: return [ LedgerEntry(memo: "Interest", credit: amount, debit: 0, date: Date.now, location: merchant, category_pair: NamedPair("Account Control", "Interest", kind: .category), account_pair: self.account) ]
        }
    }
    func validate() -> Bool {
        var emptys: [String] = [];
        
        if merchant.isEmpty { emptys.append("merchant") }
        if account.parentEmpty { emptys.append("account") }
        if account.childEmpty { emptys.append("sub account") }
        
        if !emptys.isEmpty {
            err_msg = "The following fields are empty: " + emptys.joined(separator: ", ")
            return false;
        }
        else {
            err_msg = nil;
            return true;
        }
    }
    func clear() {
        merchant = "";
        amount = 0.00;
        kind = .gift;
        account = NamedPair(kind: .account);
        err_msg = "";
    }
    
    var merchant: String = "";
    var amount: Decimal = 0;
    var kind: GeneralIncomeKind = .gift;
    var account: NamedPair = NamedPair(kind: .account);
    var err_msg: String? = nil;
}

struct GeneralIncome: View {
    @Bindable var vm: GeneralIncomeViewModel;

    var body: some View {
        VStack {
            HStack {
                Text("General Income").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundColor(.red).italic()
                }
                Spacer()
            }.padding([.leading, .trailing], 10).padding(.top, 5)
            
            HStack {
                switch vm.kind {
                case .gift: TextField("Person", text: $vm.merchant)
                case .interest: TextField("Company", text: $vm.merchant)
                }
                Text("gave the amount of ")
                TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                Text("as")
                Picker("Kind", selection: $vm.kind) {
                    Text("Gift").tag(GeneralIncomeKind.gift)
                    Text("Interest").tag(GeneralIncomeKind.interest)
                }.labelsHidden()
            }.padding([.leading, .trailing], 5).padding(.bottom, 3)
            HStack {
                Text("Into:")
                NamedPairEditor(acc: $vm.account)
            }.padding([.leading, .trailing], 10).padding(.bottom, 5)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    GeneralIncome(vm: GeneralIncomeViewModel())
}
