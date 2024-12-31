//
//  ManyManyTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class ManyManyTransferVM : TransViewBase {
    init() {
        err_msg = nil;
        top = ManyTransferTableVM();
        bottom = ManyTransferTableVM();
    }
    
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
        top.clear()
        bottom.clear()
        err_msg = nil;
    }
    
    
    var err_msg: String?;
    
    var top: ManyTransferTableVM;
    var bottom: ManyTransferTableVM;
}

struct ManyManyTransfer : View {
    @Bindable var vm: ManyManyTransferVM;
    
    var body : some View {
        VStack {
            HStack {
                Text("Many-to-One Transfer").font(.headline)
                
                if let msg = vm.err_msg {
                    Text(msg).foregroundStyle(.red).italic()
                }
                Spacer()
            }.padding(.top, 5)
            
            HStack {
                Text("Take from").italic().bold()
                Spacer()
            }
            
            ManyTransferTable(vm: vm.top)
            
            Divider()
            
            HStack {
                Text("Move to").italic().bold()
                Spacer()
            }
            
            ManyTransferTable(vm: vm.bottom).padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManyManyTransfer(vm: ManyManyTransferVM())
}
