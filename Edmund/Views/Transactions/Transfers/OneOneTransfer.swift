//
//  OneOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class OneOneTransferVM : TransViewBase {
    init() {
        err_msg = nil;
        amount = 0;
        src = AccountPair();
        dest = AccountPair();
    }
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal> {
        return [:];
    }
    func create_transactions() -> [LedgerEntry]? {
        return [];
    }
    func validate() -> Bool {
        return false;
    }
    func clear() {
        err_msg = nil;
        amount = 0;
        src = AccountPair();
        dest = AccountPair();
    }
    
    
    var err_msg: String?;
    var amount: Decimal;
    var src: AccountPair;
    var dest: AccountPair;
}

struct OneOneTransfer : View {
    @Bindable var vm: OneOneTransferVM;
    
    var body: some View {
        VStack {
            HStack {
                Text("One-to-One Transfer").font(.headline)
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)

            Grid() {
                GridRow {
                    Text("Take")
                    TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                }
                   
                GridRow {
                    Text("From")
                    AccPair(acc: $vm.src)
                }
                
                GridRow {
                    Text("Into")
                    AccPair(acc: $vm.dest)
                }
                
            }.padding(.bottom, 10).frame(minWidth: 300, maxWidth: .infinity)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    OneOneTransfer(vm: OneOneTransferVM())
}
