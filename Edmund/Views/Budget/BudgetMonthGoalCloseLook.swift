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
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 85;
    private let maxWidth: CGFloat = 95;
#else
    private let minWidth: CGFloat = 100;
    private let maxWidth: CGFloat = 110;
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
                    Text("Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        CurrencyField(over.amount)
                        Picker("", selection: $over.period) {
                            ForEach(MonthlyTimePeriods.allCases) { period in
                                Text(period.display).tag(period)
                            }
                        }.labelsHidden()
                    }
                }
                
                GridRow {
                    Text("Monthly Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    Text(over.monthlyGoal, format: .currency(code: currencyCode))
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
