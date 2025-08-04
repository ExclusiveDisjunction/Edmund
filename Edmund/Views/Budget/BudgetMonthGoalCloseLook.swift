//
//  BudgetMonthGoalCloseLook.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/3/25.
//

import SwiftUI
import EdmundCore

struct BudgetMonthGoalCloseLook<T> : View where T: BoundPair, T: TransactionHolder, T: TypeTitled, T.P: TypeTitled, T.P.C == T {
    @Bindable var over: BudgetGoalSnapshot<T>;
    
    @Environment(\.dismiss) private var dismiss;
    
#if os(macOS)
    private let minWidth: CGFloat = 70;
    private let maxWidth: CGFloat = 80;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    var body: some View {
        VStack {
            HStack {
                Text("Goal Close Look")
                    .font(.title2)
                Spacer()
            }
            
            Grid {
                GridRow {
                    Text("Target:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    NamedPairPicker($over.association)
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(over.amount)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}
