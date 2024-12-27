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

class GeneralIncomeViewModel : ObservableObject, TransViewBase {
    var id: UUID = UUID()
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        if !validate() {
            return [:];
        }
        
        return [AccountPair(account: self.account, sub_account: self.sub_account) : amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil}
        
        switch kind {
        case .gift: return [ LedgerEntry(id: UUID(), memo: "Gift from " + merchant, credit: amount, debit: 0, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Gift", tender: account, sub_tender: sub_account) ]
        case .interest: return [ LedgerEntry(id: UUID(), memo: "Interest", credit: amount, debit: 0, date: Date.now, added_on: Date.now, location: merchant, category: "Account Control", sub_category: "Interest", tender: account, sub_tender: sub_account) ]
        }
    }
    func validate() -> Bool {
        var emptys: [String] = [];
        
        if merchant.isEmpty { emptys.append("merchant") }
        if account.isEmpty { emptys.append("account") }
        if sub_account.isEmpty { emptys.append("sub account") }
        
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
        account = "";
        sub_account = "";
        err_msg = "";
    }
    
    @Published var merchant: String = "";
    @Published var amount: Decimal = 0;
    @Published var kind: GeneralIncomeKind = .gift;
    @Published var account: String = "";
    @Published var sub_account: String = "";
    @Published var err_msg: String? = nil;
}

struct GeneralIncome: View {
    var id: UUID = UUID();
    @ObservedObject var vm: GeneralIncomeViewModel;

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
                TextField("Account", text: $vm.account)
                TextField("Sub Account", text: $vm.sub_account)
            }.padding([.leading, .trailing], 10).padding(.bottom, 5)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    GeneralIncome(vm: GeneralIncomeViewModel())
}
