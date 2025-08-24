//
//  BudgetPropertiesEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDivisionPropertiesEditor : View {
    @Bindable var snapshot: ShallowIncomeDivisionSnapshot;
    let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    var body: some View {
        VStack {
            if snapshot.isFinalized {
                Text("This income division is finalized. This means no other edits can take place.")
                    .italic()
            }
            
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", text: $snapshot.name)
                        .textFieldStyle(.roundedBorder)
                        .disabled(snapshot.isFinalized)
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(snapshot.amount)
                        .disabled(snapshot.isFinalized)
                }
                
                GridRow {
                    Text("Income Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    EnumPicker(value: $snapshot.kind)
                        .disabled(snapshot.isFinalized)
                }
                
                GridRow {
                    Text("Deposit to:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    ElementPicker($snapshot.depositTo)
                        .disabled(snapshot.isFinalized)
                }
            }
            
            Spacer()
            
            if isSheet {
                HStack {
                    Spacer()
                    
                    Button("Ok") {
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                }
            }
        }.padding()
    }
}

#Preview {
    let budget = try! IncomeDivision.getExample()
    let snapshot = IncomeDivisionSnapshot(budget)
    
    IncomeDivisionPropertiesEditor(snapshot: snapshot, isSheet: false)
}
