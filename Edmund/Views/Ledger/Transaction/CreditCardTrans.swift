//
//  CreditCardTrans.swift
//  Edmund
//
//  Created by Hollan on 12/26/24.
//

import SwiftUI
import SwiftData
import EdmundCore

struct CreditCardTrans: TransactionEditorProtocol {
    private var warning = StringWarningManifest();
    
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> Bool {
        fatalError("not implemented")
    }
    
    var body: some View {
        TransactionEditorFrame(.creditCard, warning: warning, apply: apply, content: {
            Text("Work in Progress")
        })
    }
}

#Preview {
    CreditCardTrans()
        .modelContainer(Containers.debugContainer)
}
