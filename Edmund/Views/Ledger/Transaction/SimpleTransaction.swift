//
//  SimpleTransaction.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct SimpleTransaction : TransactionEditorProtocol {
    private var snapshot = LedgerEntrySnapshot();
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) private var modelContext;
    
    func apply() -> [ValidationFailure]? {
        let result = snapshot.validate(unique: uniqueEngine)
        guard result.isEmpty else {
            return result;
        }
        
        let newTrans = LedgerEntry();
        snapshot.apply(newTrans, context: modelContext, unique: uniqueEngine);
        
        modelContext.insert(newTrans);
        return nil;
    }
    
    var body: some View {
        TransactionEditorFrame(.simple, apply: apply, content: {
            LedgerEntry.EditView(snapshot)
        })
    }
}

#Preview {
    SimpleTransaction()
        .padding()
        .modelContainer(Containers.debugContainer)
}
