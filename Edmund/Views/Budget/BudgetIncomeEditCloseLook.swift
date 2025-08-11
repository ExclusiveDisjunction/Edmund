//
//  BudgetIncomeCloseLook.swift
//  Edmund
//
//  Created by Hollan Sellars on 8/3/25.
//

import EdmundCore
import SwiftUI

struct BudgetIncomeEditCloseLook : View {
    @Bindable var snapshot: BudgetIncomeSnapshot;

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
                Text("Income Close Look")
                    .font(.title2)
                Spacer()
            }
            
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("", text: $snapshot.name)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(snapshot.amount)
                }
                
                GridRow {
                    Text("Has Date:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Toggle("", isOn: $snapshot.hasDate)
                            .labelsHidden()
                        
                        Spacer()
                    }
                }
                
                if snapshot.hasDate {
                    GridRow {
                        Text("Date:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        HStack {
                            DatePicker("", selection: $snapshot.date, displayedComponents: .date)
                                .labelsHidden()
                            
                            Button("Today") {
                                snapshot.date = .now
                            }
                            
                            Spacer()
                        }
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
