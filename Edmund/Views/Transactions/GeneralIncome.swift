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
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        guard validate() else { return nil}
        guard let acc = self.account else { return nil }
        
        return [ acc.id : amount];
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil}
        
        guard let acc = self.account else { return nil }
        
        let result: LedgerEntry = switch kind {
        case .gift:
            .init(
                memo: "Gift from " + merchant,
                credit: amount,
                debit: 0,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.gift,
                account: acc
            )
        case .interest:
            .init(
                memo: "Interest",
                credit: amount,
                debit: 0,
                date: Date.now,
                location: merchant,
                category: cats.account_control.interest,
                account: acc
            )
        }
        
        return [result]
    }
    func validate() -> Bool {
        var emptys: [String] = [];
        
        if merchant.isEmpty { emptys.append("merchant") }
        if account == nil { emptys.append("account") }
        
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
        account = nil
        err_msg = "";
    }
    
    var merchant: String = "";
    var amount: Decimal = 0;
    var kind: GeneralIncomeKind = .gift;
    var account: SubAccount? = nil
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
                NamedPairPicker(target: $vm.account)
            }.padding([.leading, .trailing], 10).padding(.bottom, 5)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    GeneralIncome(vm: GeneralIncomeViewModel())
}
