//
//  ManyOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;
import EdmundCore

struct ManyOneTransfer : TransactionEditorProtocol {
    @State private var account: SubAccount? = nil;
    @State private var date: Date = .now;
    @State private var data: [ManyTableEntry] = [.init()];
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> [ValidationFailure]? {
        guard let categories = categoriesContext else {
            return [.internalError]
        }
        
        guard let destination = account else {
            return [.empty("Account")]
        }
        
        var firstTrans: [LedgerEntry];
        do {
            firstTrans = try data.createTransactions(transfer_into: false, categories)
        }
        catch let e {
            return e.data
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
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.manyOne), apply: apply, content: {
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
                            DatePicker("", selection: $date, displayedComponents: .date)
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
                    .frame(minHeight: 250)

            }
        })
    }
}

#Preview {
    ManyOneTransfer().padding().modelContainer(Containers.debugContainer)
}
