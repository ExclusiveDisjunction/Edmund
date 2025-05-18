//
//  PaydayEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/18/25.
//

import SwiftUI
import EdmundCore

struct PaydayEditor : TransactionEditorProtocol {
    var warning = StringWarningManifest();
    
    func apply() -> Bool {
        fatalError("Not implemented")
    }
    
    var body: some View {
        TransactionEditorFrame(.payday, warning: warning, apply: apply, content: {
            Text("Work in progress")
        })
    }
}

#Preview {
    PaydayEditor()
        .modelContainer(Containers.debugContainer)
}
