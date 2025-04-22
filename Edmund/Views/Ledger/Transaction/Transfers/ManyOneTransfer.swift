//
//  ManyOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

/*
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
    
}
 */

struct ManyOneTransfer : TransactionEditorProtocol {
    @State private var account: SubAccount? = nil;
    @State private var data: [ManyTableEntry] = [.init()];
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        fatalError("not implmemented")
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.manyOne), apply: apply, content: {
            VStack {
                ManyTransferTable(data: $data)
                
                Divider()
                
                HStack {
                    Text("Move")
                    Text(data.amount, format: .currency(code: currencyCode))
                    Text("into")
                    
                    NamedPairPicker($account)
                }
            }
        })
    }
}

#Preview {
    ManyOneTransfer().padding().modelContainer(Containers.debugContainer)
}
