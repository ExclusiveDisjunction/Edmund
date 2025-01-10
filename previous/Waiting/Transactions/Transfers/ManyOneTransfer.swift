//
//  ManyOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class ManyOneTransferVM : TransViewBase {
    func compile_deltas() -> Dictionary<AccountPair, Decimal>? {
        if !validate() { return nil }
        
        var result: [AccountPair: Decimal] = [
            acc: multi.total
        ];
        
        multi.entries.forEach {
            result[$0.acc] = -$0.amount
        }
        
        return result;
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil }
        
        if var sub_acc = self.multi.create_transactions(transfer_into: false) {
            sub_acc.append(
                .init(memo: "Various to " + acc.sub_account, credit: multi.total, debit: 0, date: Date.now, location: "Bank", category: .init("Account Control", "Transfer"), account: acc)
            );
            return sub_acc;
        }
        else {
            return nil;
        }
    }
    func validate() -> Bool {
        let acc_empty = self.acc.isEmpty;
        let child_empty: [Int] = self.multi.get_empty_rows();
        
        if acc_empty && !child_empty.isEmpty {
            err_msg = "Account is empty and the following lines contain empty fields: " + child_empty.map(String.init).joined(separator: ", ")
        }
        else if acc_empty {
            err_msg = "Account is empty"
        }
        else if !child_empty.isEmpty {
            err_msg = "The following lines contained empty fields: " + child_empty.map(String.init).joined(separator: ", ")
        }
        else {
            err_msg = nil;
            return true;
        }
        
        return false;
    }
    func clear() {
        err_msg = nil;
        acc = .init()
        multi.clear();
    }
     
    var err_msg: String? = nil;
    var acc: AccountPair = .init();
    var multi: ManyTransferTableVM = .init(minHeight: 90);
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
                AccountNameEditor(account: $vm.acc)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManyOneTransfer(vm: ManyOneTransferVM())
}
