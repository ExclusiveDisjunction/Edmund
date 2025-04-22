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
    @State private var date: Date = .now;
    @State private var data: [ManyTableEntry] = [.init()];
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError", title: "Error")
            return false
        }
        
        guard let destination = account else {
            warning.warning = .init(message: "emptyFields", title: "Error")
            return false;
        }
        
        guard var firstTrans = data.createTransactions(transfer_into: false, categories) else {
            warning.warning = .init(message: "missingAccount", title: "Error");
            return false;
        }
        
        firstTrans.append(
            LedgerEntry(
                name: "Various to " + destination.name,
                credit: data.amount,
                debit: 0,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: destination
            )
        );
        
        for transaction in firstTrans {
            modelContext.insert(transaction)
        }
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.manyOne), warning: warning, apply: apply, content: {
            VStack {
                Grid {
                    GridRow {
                        HStack {
                            Text("Move")
                            Text(data.amount, format: .currency(code: currencyCode))
                            Text("into:")
                        }
                        
                        HStack {
                            NamedPairPicker($account)
                            Spacer()
                        }
                    }
                    HStack {
                        Text("Date:")
                        
                        HStack {
                            DatePicker("date", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                            
                            Spacer()
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Amounts:").bold()
                }
                
                ManyTransferTable(data: $data)
            

            }
        })
    }
}

#Preview {
    ManyOneTransfer().padding().modelContainer(Containers.debugContainer)
}
