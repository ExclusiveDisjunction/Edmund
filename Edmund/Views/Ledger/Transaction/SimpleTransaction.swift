//
//  SimpleTransaction.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/22/25.
//

import SwiftUI
import SwiftData

struct SimpleTransaction : TransactionEditorProtocol {
    private var snapshot = LedgerEntrySnapshot();
    
    @Environment(\.uniqueEngine) private var uniqueEngine;
    @Environment(\.modelContext) private var modelContext;
    
    func apply() -> ValidationFailure? {
        if let result = snapshot.validate(unique: uniqueEngine) {
            return result
        }
        
        let newTrans = LedgerEntry();
        newTrans.update(snapshot, unique: uniqueEngine)
        
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
    DebugContainerView {
        SimpleTransaction()
            .padding()
    }
}
