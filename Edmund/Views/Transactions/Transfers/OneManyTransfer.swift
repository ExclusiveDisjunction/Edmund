//
//  Transfers.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI

@Observable
class OneManyTransferVM : TransViewBase {
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        if !self.validate() { return nil; }
        
        var result: [NamedPair: Decimal] = [
            acc: -amount
        ];
        
        multi.entries.forEach {
            result[$0.acc] = $0.amount
        }
        
        return result;
    }
    func create_transactions() -> [LedgerEntry]? {
        if !self.validate() { return nil; }
        
        var result: [LedgerEntry] = [
            LedgerEntry(memo: self.acc.child + " to Various", credit: 0, debit: amount, date: Date.now, location: "Bank", category_pair: NamedPair("Account Control", "Transfer", kind: .category), account_pair: acc)
        ];
        
        if let sub_result = self.multi.create_transactions(transfer_into: true) {
            result.append(contentsOf: sub_result)
            
            return result;
        }
        else {
            return nil;
        }
    }
    func validate() -> Bool {
        let acc_empty = acc.isEmpty;
        let empty_rows = multi.get_empty_rows();
        
        if acc_empty && !empty_rows.isEmpty {
            err_msg = "Account is empty and the following rows contain empty fields: " + empty_rows.map(String.init).joined(separator: ", ");
        }
        else if acc_empty {
            err_msg = "Account is empty";
        }
        else if !empty_rows.isEmpty {
            err_msg = "The following rows contain empty fields: " + empty_rows.map(String.init).joined(separator: ", ");
        }
        else {
            err_msg = nil;
            return true;
        }
        
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
