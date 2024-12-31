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
        src = NamedPair(kind: .account);
        dest = NamedPair(kind: .account);
    }
    
    func compile_deltas() -> Dictionary<NamedPair, Decimal>? {
        if !validate() { return nil; }
        
        return [
            src: -amount,
            dest: amount
        ];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        return [
            LedgerEntry(memo: src.child + " to " + dest.child, credit: 0, debit: amount, date: Date.now, location: "Bank", category_pair: NamedPair("Account Control", "Transfer", kind: .category), account_pair: src),
            LedgerEntry(memo: src.child + " to " + dest.child, credit: amount, debit: 0, date: Date.now, location: "Bank", category_pair: NamedPair("Account Control", "Transfer", kind: .category), account_pair: dest)
        ];
    }
    func validate() -> Bool {
        if src.isEmpty && dest.isEmpty {
            err_msg = "Source and Destination accounts are empty";
        }
        else if src.isEmpty {
            err_msg = "Source account is empty";
        }
        else if dest.isEmpty {
            err_msg = "Destination account is empty";
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
        src = NamedPair(kind: .account);
        dest = NamedPair(kind: .account);
    }
    
    
    var err_msg: String?;
    var amount: Decimal;
    var src: NamedPair;
    var dest: NamedPair;
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
                    NamedPairEditor(acc: $vm.src)
                }
                
                GridRow {
                    Text("Into")
                    NamedPairEditor(acc: $vm.dest)
                }
                
            }.padding(.bottom, 10).frame(minWidth: 300, maxWidth: .infinity)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    OneOneTransfer(vm: OneOneTransferVM())
}
