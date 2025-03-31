//
//  OneOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class OneOneTransferVM : TransactionEditor {
    init() {
        err_msg = nil;
        amount = 0;
        src = nil
        dest = nil
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        if !validate() { return nil; }
        guard let src = self.src, let dest = self.dest else { return nil}
        
        return [
            src.id: -amount,
            dest.id: amount
        ];
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil; }
        
        guard let src = self.src, let dest = self.dest else { return nil }
        
        return [
            .init(
                memo: src.name + " to " + dest.name,
                credit: 0,
                debit: amount,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.transfer,
                account: src
            ),
            .init(
                memo: src.name + " to " + dest.name,
                credit: amount,
                debit: 0,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.transfer,
                account: dest
            )
        ];
    }
    func validate() -> Bool {
        if src == nil && dest == nil{
            err_msg = "Source and Destination accounts are empty";
        }
        else if src == nil {
            err_msg = "Source account is empty";
        }
        else if dest == nil{
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
        src = nil
        dest = nil
    }
    
    
    var err_msg: String?;
    var amount: Decimal;
    var src: SubAccount?;
    var dest: SubAccount?;
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
                    NamedPairPicker(target: $vm.src)
                }
                
                GridRow {
                    Text("Into")
                    NamedPairPicker(target: $vm.dest)
                }
                
            }.padding(.bottom, 10).frame(minWidth: 300, maxWidth: .infinity)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    OneOneTransfer(vm: OneOneTransferVM())
}
