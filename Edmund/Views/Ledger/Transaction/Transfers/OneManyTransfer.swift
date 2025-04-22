//
//  Transfers.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI

/*
@Observable
class OneManyTransferVM : TransactionEditor {
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        if !self.validate() { return nil; }
        guard let acc = self.acc else { return nil }
        
        var result: [UUID: Decimal] = [
            acc.id: -amount
        ];
        
        multi.entries.forEach {
            guard let acc = $0.account else { return }
            result[acc.id] = $0.amount
        }
        
        return result;
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !self.validate() { return nil; }
        guard let acc = self.acc else { return nil }
        
        var result: [LedgerEntry] = [
            .init(
                memo: acc.name + " to Various",
                credit: 0,
                debit: amount,
                date: Date.now,
                location: "Bank",
                category: cats.account_control.transfer,
                account: acc)
        ];
        
        if let sub_result = self.multi.create_transactions(transfer_into: true, cats) {
            result.append(contentsOf: sub_result)
            
            return result;
        }
        else {
            return nil;
        }
    }
    func validate() -> Bool {
        let acc_empty = acc == nil;
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
        acc = nil
        multi.clear();
    }
     
    var err_msg: String? = nil;
    
    
}
*/
 
struct OneManyTransfer : TransactionEditorProtocol {
    @State private var date: Date = Date.now;
    @State private var account: SubAccount? = nil
    @State private var data: [ManyTableEntry] = [.init()];
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        fatalError("not implemented")
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.oneMany), apply: apply, content: {
            VStack {
                HStack {
                    Text("Source:", comment: "Account source")
                    NamedPairPicker($account)
                }
                
                ManyTransferTable(data: $data)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Text("will be moved", comment: "$ will be moved")
                }
                
            }
        })
    }
}

#Preview {
    OneManyTransfer()
}
