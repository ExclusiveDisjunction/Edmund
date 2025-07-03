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
    @Environment(\.modelContext) private var modelContext;
    @Environment(\.categoriesContext) private var categoriesContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    func apply() -> ValidationFailure? {
        return .internalError
    }
    
    var body: some View {
        TransactionEditorFrame(.creditCard, apply: apply, content: {
            Text("Work in Progress")
        })
    }
}

#Preview {
    CreditCardTrans()
        .modelContainer(try! Containers.debugContainer())
}
