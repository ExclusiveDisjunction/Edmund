//
//  BudgetPropertiesEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct BudgetPropertiesEditor : View {
    @Bindable var snapshot: IncomeDividerInstanceSnapshot;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("", text: $snapshot.name)
            }
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                CurrencyField(snapshot.amount)
            }
            
            GridRow {
                Text("Income Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                Picker("", selection: $snapshot.kind) {
                    ForEach(IncomeKind.allCases, id: \.id) { kind in
                        Text(kind.display).tag(kind)
                    }
                }.pickerStyle(.segmented)
                    .labelsHidden()
            }
            
            GridRow {
                Text("Deposit to:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                NamedPairPicker($snapshot.depositTo)
            }
        }.padding()
    }
}

#Preview {
    let budget = try! IncomeDividerInstance.getExampleBudget()
    let snapshot = IncomeDividerInstanceSnapshot(budget)
    
    BudgetPropertiesEditor(snapshot: snapshot)
}
