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

    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> [ValidationFailure]? {
        guard let categories = categoriesContext else {
            return [.internalError]
        }
        
        guard let source = account else {
            return [.empty("Account")]
        }
        
        let subTrans: [LedgerEntry]
        do {
            subTrans = try data.createTransactions(transfer_into: true, categories)
        }
        catch let e {
            return e.data
        }
        
        modelContext.insert(
            LedgerEntry(
                name: source.name + " to Various",
                credit: 0,
                debit: data.amount,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: source
            )
        );
        
        for transaction in subTrans {
            modelContext.insert(transaction)
        }
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.oneMany), apply: apply, content: {
            VStack {
                HStack {
                    Text("Source:", comment: "Account source")
                    NamedPairPicker($account)
                }
                
                ManyTransferTable(data: $data)
                    .frame(minHeight: 250)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Text("will be moved to", comment: "$ will be moved to")
                    if let account = account {
                        CompactNamedPairInspect(account)
                    }
                    else {
                        Text("(no account)").italic()
                    }
                }

                HStack {
                    Text("Date:")
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                    Button("Today", action: {
                        date = .now
                    })
                    Spacer()
                }
                
            }
        })
    }
}

#Preview {
    OneManyTransfer()
}
