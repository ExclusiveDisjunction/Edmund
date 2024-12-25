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
    
    func compile_deltas() -> Dictionary<String, Decimal> {
        if !validate() {
            return [:];
        }
        
        return [tender + "." + sub_tender : amount];
    }
    func create_transactions() throws(TransactionError) -> [LedgerEntry] {
        guard !merchant.isEmpty else { throw TransactionError(kind: .empty_argument, on: "merchant") }
        guard !tender.isEmpty else { throw TransactionError(kind: .empty_argument, on: "account")}
        guard !sub_tender.isEmpty else { throw TransactionError(kind: .empty_argument, on: "sub account")}
        
        switch kind {
        case .gift: return [ LedgerEntry(id: UUID(), memo: "Gift from " + merchant, credit: amount, debit: 0, date: Date.now, added_on: Date.now, location: "Bank", category: "Account Control", sub_category: "Gift", tender: tender, sub_tender: sub_tender) ]
        case .interest: return [ LedgerEntry(id: UUID(), memo: "Interest", credit: amount, debit: 0, date: Date.now, added_on: Date.now, location: merchant, category: "Account Control", sub_category: "Interest", tender: tender, sub_tender: sub_tender) ]
        }
    }
    func validate() -> Bool {
        var emptys: [String] = [];
        
        if merchant.isEmpty { emptys.append("merchant") }
        if tender.isEmpty { emptys.append("account") }
        if sub_tender.isEmpty { emptys.append("sub account") }
        
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
        tender = "";
        sub_tender = "";
        err_msg = "";
    }
    
    @Published var merchant: String = "";
    @Published var amount: Decimal = 0;
    @Published var kind: GeneralIncomeKind = .gift;
    @Published var tender: String = "";
    @Published var sub_tender: String = "";
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
                TextField("Account", text: $vm.tender)
                TextField("Sub Account", text: $vm.sub_tender)
            }.padding([.leading, .trailing], 10).padding(.bottom, 5)
        }.background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    GeneralIncome(vm: GeneralIncomeViewModel())
}
