//
//  ManyOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

@Observable
class ManyOneTransferVM : TransactionEditor {
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        if !validate() { return nil }
        guard let acc = self.acc else { return nil }
        
        var result: [UUID: Decimal] = [
            acc.id: multi.total
        ];
        
        multi.entries.forEach {
            guard let acc = $0.account else { return }
            result[acc.id] = -$0.amount
        }
        
        return result;
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil }
        guard let acc = self.acc else { return nil }
        
        if var sub_acc = self.multi.create_transactions(transfer_into: false, cats) {
            sub_acc.append(
                .init(
                    memo: "Various to " + acc.name,
                    credit: multi.total,
                    debit: 0,
                    date: Date.now,
                    location: "Bank",
                    category: cats.account_control.transfer,
                    account: acc)
            );
            return sub_acc;
        }
        else {
            return nil;
        }
    }
    func validate() -> Bool {
        let acc_empty = self.acc == nil;
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
        acc = nil
        multi.clear();
    }
     
    var err_msg: String? = nil
    var acc: SubAccount? = nil
    var multi: ManyTransferTableVM = .init();
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
                NamedPairPicker<SubAccount>(target: $vm.acc)
            }.padding(.bottom, 5)
        }.padding([.leading, .trailing], 10).background(.background.opacity(0.5)).cornerRadius(5)
    }
}

#Preview {
    ManyOneTransfer(vm: ManyOneTransferVM())
}
