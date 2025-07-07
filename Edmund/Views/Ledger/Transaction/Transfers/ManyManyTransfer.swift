//
//  ManyManyTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;
import EdmundCore

struct ManyManyTransfer : TransactionEditorProtocol {
    @State private var top: [ManyTableEntry] = [.init()];
    @State private var bottom: [ManyTableEntry] = [.init()];
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";

    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
    
        let topAmount = top.amount, bottomAmount = bottom.amount;
        guard topAmount != bottomAmount else {
            return .invalidInput
        }
        
        let topData: [LedgerEntry], bottomData: [LedgerEntry];
        do {
            topData = try top.createTransactions(transfer_into: false, categories);
            bottomData = try bottom.createTransactions(transfer_into: false, categories);
        }
        catch let e {
            return e
        }
        
        let totalData = topData + bottomData
        
        for transaction in totalData {
            modelContext.insert(transaction);
        }
        
        return nil;
    }
    
    var body : some View {
        TransactionEditorFrame(.transfer(.manyMany), apply: apply, content: {
            VStack {
                ManyTransferTable(title: "Take from", data: $top)
                    .frame(minHeight: 150)
                
                HStack {
                    Text("Total:")
                    Text(top.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
                
                Divider()
                
                ManyTransferTable(title: "Move to", data: $bottom)
                    .frame(minHeight: 150)
                
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
    DebugContainerView {
        ManyManyTransfer()
            .padding()
    }
}
