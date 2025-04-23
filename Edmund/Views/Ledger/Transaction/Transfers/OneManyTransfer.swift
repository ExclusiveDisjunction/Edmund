//
//  Transfers.swift
//  Edmund
//
//  Created by Hollan on 12/27/24.
//

import SwiftUI
import EdmundCore
 
struct OneManyTransfer : TransactionEditorProtocol {
    @State private var date: Date = Date.now;
    @State private var account: SubAccount? = nil
    @State private var data: [ManyTableEntry] = [.init()];
    private var warning = StringWarningManifest();

    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "noCategories")
            return false
        }
        
        guard let source = account else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        var firstTrans = [
            LedgerEntry(
                name: source.name + " to Various",
                credit: 0,
                debit: data.amount,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: source
            )
        ];
        guard let new = data.createTransactions(transfer_into: true, categories) else {
            warning.warning = .init(message: "missingAccount");
            return false;
        }
        
        firstTrans.append(contentsOf: new);
        
        for transaction in firstTrans {
            modelContext.insert(transaction)
        }
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.oneMany), warning: warning, apply: apply, content: {
            VStack {
                HStack {
                    Text("Source:", comment: "Account source")
                    NamedPairPicker($account)
                }
                
                ManyTransferTable(data: $data)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Text("will be moved to", comment: "$ will be moved to")
                    if let account = account {
                        NamedPairViewer(account)
                    }
                    else {
                        Text("(no account)").italic()
                    }
                }
                
                DatePicker("Date:", selection: $date, displayedComponents: .date)
                
            }
        })
    }
}

#Preview {
    OneManyTransfer()
}
