//
//  ManyManyTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

/*
@Observable
class ManyManyTransferVM : TransactionEditor {
    init() {
        err_msg = nil;
        top = ManyTransferTableVM();
        bottom = ManyTransferTableVM();
    }
    
    func compile_deltas() -> Dictionary<UUID, Decimal>? {
        guard validate() else { return nil }
        
        var result: [UUID: Decimal] = [:];
        
        top.entries.forEach {
            guard let acc = $0.account else { return }
            result[acc.id] = $0.amount
        }
        bottom.entries.forEach{
            guard let acc = $0.account else { return }
            result[acc.id] = -$0.amount
        }
        
        return result;
    }
    func create_transactions(_ cats: CategoriesContext) -> [LedgerEntry]? {
        if !validate() { return nil }
        
        if var a = top.create_transactions(transfer_into: false, cats), let b = bottom.create_transactions(transfer_into: true, cats) {
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
*/

struct ManyManyTransfer : TransactionEditorProtocol {
    
    @State private var top: [ManyTableEntry] = [.init()];
    @State private var bottom: [ManyTableEntry] = [.init()];
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "noCategories", title: "Error")
            return false
        }
        
        guard top.amount == bottom.amount else {
            warning.warning = .init(message: "Please ensure that the top total matches the bottom total", title: "Error")
            return false;
        }
        
        guard var data = top.createTransactions(transfer_into: false, categories) else {
            warning.warning = .init(message: "missingAccount", title: "Error");
            return false;
        }
        guard let bottomData = bottom.createTransactions(transfer_into: true, categories) else {
            warning.warning = .init(message: "missingAccount", title: "Error");
            return false;
        }
        
        data.append(contentsOf: bottomData);
        
        for transaction in data {
            modelContext.insert(transaction);
        }
        
        return true;
    }
    
    var body : some View {
        TransactionEditorFrame(.transfer(.manyMany), warning: warning, apply: apply, content: {
            VStack {
                HStack {
                    Text("Take from").italic().bold()
                    Spacer()
                }
                
                ManyTransferTable(data: $top)
                
                HStack {
                    Text("Total:")
                    Text(top.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    Text("Move to").italic().bold()
                    Spacer()
                }
                
                ManyTransferTable(data: $bottom)
                
                HStack {
                    Text("Total:")
                    Text(bottom.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
        })
    }
}

#Preview {
    ManyManyTransfer().padding().modelContainer(Containers.debugContainer)
}
