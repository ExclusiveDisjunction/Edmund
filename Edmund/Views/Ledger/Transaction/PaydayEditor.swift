//
//  PaydayEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/18/25.
//

import SwiftUI

struct PaydayEditor : TransactionEditorProtocol {
    func apply() -> [ValidationFailure]? {
        return [.internalError]
    }
    
    var body: some View {
        TransactionEditorFrame(.payday, apply: apply, content: {
            Text("Work in progress")
        })
    }
}

#Preview {
    PaydayEditor()
        .modelContainer(Containers.debugContainer)
}
