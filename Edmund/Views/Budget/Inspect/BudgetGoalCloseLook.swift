//
//  BudgetGoalCloseLook.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/22/25.
//

import SwiftUI

struct BudgetGoalCloseLook<T> : View where T: BudgetGoal {
    var source: BudgetGoalData<T>;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @Environment(\.dismiss) private var dismiss;
    
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
                    
                    HStack {
                        ElementDisplayer(value: source.over.association)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.over.amount, format: .currency(code: currencyCode))
                        Text(source.over.period.display)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Monthly Goal:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.over.monthlyGoal, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Progress:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.balance, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Money Left:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.freeToSpend, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Over By:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(source.overBy, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
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
