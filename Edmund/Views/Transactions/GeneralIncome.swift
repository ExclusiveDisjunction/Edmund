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
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal>? {
        if !validate() {
            return [:];
        }
        
        return [ account : amount];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil}
        
        let result: LedgerEntry = switch kind {
        case .gift:
            .init(
                memo: "Gift from " + merchant,
                credit: amount,
                debit: 0,
                date: Date.now,
                location: "Bank",
                category: .init("Account Control", "Gift"),
                account: account
            )
        case .interest:
            .init(
                memo: "Interest",
                credit: amount,
                debit: 0,
                date: Date.now,
                location: merchant,
                category: .init("Account Control", "Interest"),
                account: self.account
            )
        }
        
        return [result]
    }
    func validate() -> Bool {
        var emptys: [String] = [];
        
        if merchant.isEmpty { emptys.append("merchant") }
        if account.isEmpty { emptys.append("account") }
        
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
        account = .init()
        err_msg = "";
    }
    
    var merchant: String = "";
    var amount: Decimal = 0;
    var kind: GeneralIncomeKind = .gift;
    var account: AccountPair = .init()
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
                AccountNameEditor(account: $vm.account)
            }.padding([.leading, .trailing], 10).padding(.bottom, 5)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    GeneralIncome(vm: GeneralIncomeViewModel())
}
