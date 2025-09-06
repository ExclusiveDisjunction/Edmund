//
//  ManyManyTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;
import EdmundCore

struct ManyManyTransfer : TransactionEditorProtocol {
    private var top: ManyTableManifest = .init(isSource: true)
    private var bottom: ManyTableManifest = .init(isSource: false)
    @State private var date: Date = .now;
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";

    func apply() -> ValidationFailure? {
        guard let categories = categoriesContext else {
            return .internalError
        }
    
        let topAmount = top.amount, bottomAmount = bottom.amount;
        guard topAmount == bottomAmount else {
            return .invalidInput
        }
        
        let newTrans: [LedgerEntry];
        do {
            let topData: [LedgerEntry] = try top.createTransactions(date: date, cats: categories);
            let bottomData: [LedgerEntry] = try bottom.createTransactions(date: date, cats: categories)
            
            newTrans = topData + bottomData;
        }
        catch let e {
            return e
        }
        
        for transaction in newTrans {
            modelContext.insert(transaction);
        }
        
        return nil;
    }
    
    @ViewBuilder
    private var stats: some View {
        HStack {
            Text("Transfer Out:")
            Text(top.amount, format: .currency(code: currencyCode))
        }
        
        HStack {
            Text("Transfer In:")
            Text(bottom.amount, format: .currency(code: currencyCode))
        }
    }
    
    var body : some View {
        TransactionEditorFrame(.transfer(.manyMany), apply: apply, content: {
            VStack {
                HStack {
                    Text("Date:")
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                    
                    Button("Today") {
                        date = .now
                    }
                }
                
                if horizontalSizeClass == .compact {
                    VStack {
                        stats
                    }
                }
                else {
                    HStack {
                        stats
                    }
                }
                
                TabView {
                    ManyTransferTable(title: nil, data: top)
                        .frame(minHeight: 150, idealHeight: 350)
                        .tabItem {
                            Label("Take from", systemImage: "arrow.up.right")
                        }
                    
                    ManyTransferTable(title: nil, data: bottom)
                        .frame(minHeight: 150, idealHeight: 350)
                        .tabItem {
                            Label("Move To", systemImage: "arrow.down.right")
                        }
                }
                
            }
        })
    }
}

#Preview {
    DebugContainerView {
        ManyManyTransfer()
    }
}
