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
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        if !validate() { return nil }
        
        var result: [NamedPair: Decimal] = [:];
        
        top.entries.forEach { result[$0.acc] = $0.amount }
        bottom.entries.forEach{ result[$0.acc] = -$0.amount }
        
        return result;
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        if var a = top.create_transactions(transfer_into: false), let b = bottom.create_transactions(transfer_into: true) {
            a.append(contentsOf: b);
            return a;
        }
        else {
            return nil;
        }
    }
    func validate() -> Bool {
        let top: [Int] = top.get_empty_rows(), bottom: [Int] = bottom.get_empty_rows();
        
        if !top.isEmpty && !bottom.isEmpty {
            err_msg = "The following rows contain empty fields: top: \(top.map(String.init).joined(separator: ", ")); bottom: \(bottom.map(String.init).joined(separator: ", "))";
        }
        else if !top.isEmpty {
           err_msg = "The following rows contain empty fields in the top box: " + top.map(String.init).joined(separator: ", ");
        }
        else if !bottom.isEmpty {
            err_msg = "The following rows contain empty fields in the bottom box: " + bottom.map(String.init).joined(separator: ", ");
        }
        else {
            err_msg = nil;
        }
        
        if self.top.total != self.bottom.total {
            if err_msg == nil || err_msg!.isEmpty {
                err_msg = "Balances do not match";
            }
            else if err_msg!.isEmpty {
                err_msg! += " and the balances do not match";
            }
        }
        
        return err_msg != nil;
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
