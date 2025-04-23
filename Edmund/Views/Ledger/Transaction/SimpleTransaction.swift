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
    private var warning = StringWarningManifest();
    @Environment(\.modelContext) private var modelContext;
    
    func apply() -> Bool {
        guard snapshot.validate() else {
            warning.warning = .init(message: "Please fix all fields.");
            return false;
        }
        
        let newTrans = LedgerEntry();
        snapshot.apply(newTrans, context: modelContext);
        
        modelContext.insert(newTrans);
        return true;
    }
    
    var body: some View {
        TransactionEditorFrame(.simple, warning: warning, apply: apply, content: {
            LedgerEntry.EditView(snapshot)
        })
    }
}

#Preview {
    SimpleTransaction()
        .padding()
        .modelContainer(Containers.debugContainer)
}
