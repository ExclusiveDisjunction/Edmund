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
        src = .init()
        dest = .init()
    }
    
    func compile_deltas() -> Dictionary<AccountPair, Decimal>? {
        if !validate() { return nil; }
        
        return [
            src: -amount,
            dest: amount
        ];
    }
    func create_transactions() -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        return [
            .init(
                memo: src.sub_account + " to " + dest.sub_account,
                credit: 0,
                debit: amount,
                date: Date.now,
                location: "Bank",
                category: .init("Account Control", "Transfer"),
                account: src
            ),
            .init(
                memo: src.sub_account + " to " + dest.sub_account,
                credit: amount,
                debit: 0,
                date: Date.now,
                location: "Bank",
                category: .init("Account Control", "Transfer"),
                account: dest
            )
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
        src = .init()
        dest = .init()
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
                    AccountNameEditor(account: $vm.src)
                }
                
                GridRow {
                    Text("Into")
                    AccountNameEditor(account: $vm.dest)
                }
                
            }.padding(.bottom, 10).frame(minWidth: 300, maxWidth: .infinity)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    OneOneTransfer(vm: OneOneTransferVM())
}
