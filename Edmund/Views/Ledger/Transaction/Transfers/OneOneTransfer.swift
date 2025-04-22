//
//  OneOneTransfer.swift
//  Edmund
//
//  Created by Hollan on 12/28/24.
//

import SwiftUI;

struct OneOneTransfer : View, TransactionEditorProtocol {
    @Environment(\.categoriesContext) private var categories: CategoriesContext?;
    @Environment(\.modelContext) private var modelContext;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @State private var src: SubAccount?;
    @State private var dest: SubAccount?
    @State private var amount: Decimal = 0.0;
    @State private var date = Date.now;
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 70;
    let maxWidth: CGFloat = 80;
#endif
    
    
    func apply(_ warning: StringWarningManifest) -> Bool {
        guard let categories = categories else {
            warning.warning = .init(message: "noCategories", title: "Error")
            return false
        }
        guard let source = src, let destination = dest else {
            warning.warning = .init(message: "emptyFields", title: "Error")
            return false;
        }
        guard amount > 0.0 else {
            warning.warning = .init(message: "negativeAmount", title: "Error")
            return false
        }
        
        let trans: [LedgerEntry] = [
            .init(
                name: source.name + " to " + destination.name,
                credit: 0,
                debit: amount,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: src!
            ),
            .init(
                name: source.name + " to " + destination.name,
                credit: amount,
                debit: 0,
                date: date,
                location: "Bank",
                category: categories.accountControl.transfer,
                account: dest!
            )
        ]
        
        for item in trans { modelContext.insert(item) }
        
        return true
    }
    
    var body: some View {
        TransactionEditorFrame(.transfer(.oneOne), apply: apply, content: {
            Grid() {
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("From:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        NamedPairPicker($src)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Into:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        NamedPairPicker($dest)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("Date", selection: $date, displayedComponents: .date).labelsHidden()
                        Spacer()
                    }
                }
                
            }.frame(minWidth: 300, maxWidth: .infinity)
        })
    }
}

#Preview {
    OneOneTransfer().modelContainer(Containers.debugContainer).padding()
}
