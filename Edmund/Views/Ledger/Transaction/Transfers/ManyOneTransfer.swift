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
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "internalError")
            return false
        }
        
        guard let destination = account else {
            warning.warning = .init(message: "emptyFields")
            return false;
        }
        
        guard var firstTrans = data.createTransactions(transfer_into: false, categories) else {
            warning.warning = .init(message: "missingAccount");
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
                    .frame(minHeight: 250)

            }
        })
    }
}

#Preview {
    ManyOneTransfer().padding().modelContainer(Containers.debugContainer)
}
