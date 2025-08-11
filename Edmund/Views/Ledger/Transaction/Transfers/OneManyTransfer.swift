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
    @State private var data: ManyTableManifest = .init(isSource: false)

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 45;
    private let maxWidth: CGFloat = 55;
#else
    private let minWidth: CGFloat = 55;
    private let maxWidth: CGFloat = 60;
#endif
    
    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
        
        guard let source = account else {
            return .empty
        }
        
        let subTrans: [LedgerEntry]
        let beginTrans = LedgerEntry(
            name: source.name + " to Various",
            credit: 0,
            debit: data.amount,
            date: date,
            location: "Bank",
            category: categories.accountControl.transfer,
            account: source
        );
        
        do {
            let result = try data.createTransactions(date: date, cats: categories)
            subTrans = [beginTrans] + result;
        }
        catch let e {
            return e
        }
        
        for transaction in subTrans {
            modelContext.insert(transaction)
        }
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.oneMany), apply: apply) {
            VStack {
                Grid {
                    GridRow {
                        Text("Source:", comment: "Account source")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        NamedPairPicker($account)
                    }
                    
                    GridRow {
                        Text("Date:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        HStack {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                            
                            Button("Today", action: {
                                date = .now
                            })
                            
                            Spacer()
                        }
                    }
                }
                
                ManyTransferTable(title: nil, data: data)
                    .frame(minHeight: 250)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Text("will be moved to", comment: "$ will be moved to")
                    CompactNamedPairInspect(account)
                }
            }
        }
    }
}

#Preview {
    OneManyTransfer()
}
