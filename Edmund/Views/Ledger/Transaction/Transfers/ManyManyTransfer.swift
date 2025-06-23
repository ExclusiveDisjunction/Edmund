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
    
    func apply() -> [ValidationFailure]? {
        guard let categories = categoriesContext else {
            return [.internalError]
        }
        
        var result: [ValidationFailure] = [];
        let topAmount = top.amount, bottomAmount = bottom.amount;
        if topAmount != bottomAmount {
            if topAmount > bottomAmount {
                result.append(.tooLargeAmount("Top Total"))
                result.append(.tooSmallAmount("Bottom Total"))
            }
            else {
                result.append(.tooSmallAmount("Top Total"))
                result.append(.tooLargeAmount("Bottom Total"))
            }
        }
        
        let topData: [LedgerEntry], bottomData: [LedgerEntry];
        do {
            topData = try top.createTransactions(transfer_into: false, categories);
            bottomData = try bottom.createTransactions(transfer_into: false, categories);
        }
        catch let e {
            return result + e.data;
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
                HStack {
                    Text("Take from").italic().bold()
                    Spacer()
                }
                
                ManyTransferTable(data: $top)
                    .frame(minHeight: 150)
                
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
    ManyManyTransfer().padding().modelContainer(Containers.debugContainer)
}
