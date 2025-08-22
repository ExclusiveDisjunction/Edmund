//
//  ManyOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;
import EdmundCore

struct ManyOneTransfer : TransactionEditorProtocol {
    @State private var account: Account? = nil;
    @State private var date: Date = .now;
    @Bindable private var data: ManyTableManifest = .init(isSource: true);
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        guard let destination = account else {
            return .empty
        }
        
        var firstTrans: [LedgerEntry];
        do {
            firstTrans = try data.createTransactions(date: date, cats: categories)
        }
        catch let e {
            return e
        }
        
        firstTrans.append(
            LedgerEntry(
                name: "Various to " + destination.name,
                credit: data.amount,
                debit: 0,
                date: date,
                location: "Bank",
                category: categories.transfers,
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
                        Text("Amount:")
                        
                        HStack {
                            Text(data.amount, format: .currency(code: currencyCode))
                            
                            Spacer()
                        }
                    }
                    
                    GridRow {
                        Text("Deposit To:")
                        
                        ElementPicker($account)
                    }
                    
                    GridRow {
                        Text("Date:")
                        
                        HStack {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                            
                            Button("Today") {
                                date = .now
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Divider()
                
                ManyTransferTable(title: "Amounts:", data: data)
                    .frame(minHeight: 250)

            }
        })
    }
}

#Preview {
    DebugContainerView {
        ManyOneTransfer()
            .padding()
    }
}
