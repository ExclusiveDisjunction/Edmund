//
//  BudgetCloseInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/6/25.
//

import EdmundCore
import SwiftUI

struct BudgetCloseInspect : View {
    let data: BudgetInstance;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @Environment(\.dismiss) private var dismiss;
    
    #if os(macOS)
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
    #else
    private let minWidth: CGFloat = 100;
    private let maxWidth: CGFloat = 110;
    #endif
    
    var body: some View {
        VStack {
            Text("Income Division Close Look")
                    .font(.title2)
            
            Grid {
                GridRow {
                    Text("Name:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.name)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Income:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Deposit To:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        CompactNamedPairInspect(data.depositTo)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Last Viewed:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.lastViewed.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Last Edited:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Ok", action: { dismiss() } )
                    .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

#Preview {
    BudgetCloseInspect(data: try! .getExampleBudget())
        .modelContainer(try! Containers.debugContainer())
}
