//
//  ManyOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class ManyOneTransferVM : TransViewBase {
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
        acc = AccountPair(account: "", sub_account: "");
        multi.clear();
    }
     
    var err_msg: String? = nil;
    var acc: AccountPair = AccountPair(account: "", sub_account: "");
    var multi: ManyTransferTableVM = ManyTransferTableVM(minHeight: 90);
}
struct ManyOneTransfer : View {
    
    @Bindable var vm: ManyOneTransferVM;
    @State private var selected: UUID?;
    
    var body: some View {
        VStack {
            HStack {
                Text("Many-to-One Transfer").font(.headline)
                
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            ManyTransferTable(vm: vm.multi)
            
            Divider()
            
            HStack {
                Text("Move \(vm.multi.total, format: .currency(code: "USD")) into")
                AccPair(acc: $vm.acc)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManyOneTransfer(vm: ManyOneTransferVM())
}
