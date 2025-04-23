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
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        guard let categories = categoriesContext else {
            warning.warning = .init(message: "noCategories")
            return false
        }
        
        guard top.amount == bottom.amount else {
            warning.warning = .init(message: "Please ensure that the top total matches the bottom total")
            return false;
        }
        
        guard var data = top.createTransactions(transfer_into: false, categories) else {
            warning.warning = .init(message: "missingAccount");
            return false;
        }
        guard let bottomData = bottom.createTransactions(transfer_into: true, categories) else {
            warning.warning = .init(message: "missingAccount");
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
