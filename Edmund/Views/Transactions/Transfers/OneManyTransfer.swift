//
//  Transfers.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI

@Observable
class OneManyTransferVM : TransViewBase {
    func compile_deltas() -> Dictionary<NamedPair, Decimal> {
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
        acc = NamedPair(kind: .account);
        multi.clear();
    }
     
    var err_msg: String? = nil;
    var amount: Decimal = 0.0;
    var acc: NamedPair = NamedPair(kind: .account);
    var multi: ManyTransferTableVM = ManyTransferTableVM();
}
struct OneManyTransfer : View {
    
    @Bindable var vm: OneManyTransferVM;
    @State private var selected: UUID?;
    
    var body: some View {
        VStack {
            HStack {
                Text("One-to-Many Transfer").font(.headline)
                
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            Grid() {
                GridRow {
                    Text("Move")
                    TextField("Amount", value: $vm.amount, format: .currency(code: "USD"))
                }
                GridRow {
                    Text("From")
                    NamedPairEditor(acc: $vm.acc)
                }
            }
            
            HStack {
                Text("Into").bold().italic()
                Spacer()
            }
            
            ManyTransferTable(vm: vm.multi)
            
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    OneManyTransfer(vm: OneManyTransferVM())
}
