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
        return Dictionary<String, Decimal>();
    }
    func create_transactions() throws(TransactionError) -> [LedgerEntry] {
        return [];
    }
    func validate() -> Bool {
        do {
            let _ = try create_transactions();
            return true
        } catch let e {
            err_msg = e.localizedDescription;
            return false;
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
