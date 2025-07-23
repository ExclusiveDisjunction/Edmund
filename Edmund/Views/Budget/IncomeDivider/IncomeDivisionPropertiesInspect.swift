//
//  BudgetPropertiesInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDivisionPropertiesInspect : View {
    var data: IncomeDividerInstance;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#endif
    
    var body: some View {
        VStack {
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
                    Text("Amount:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Income Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.kind.display)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Deposit to:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        CompactNamedPairInspect(data.depositTo)
                        Spacer()
                    }
                }
            }
        }.padding()
    }
}

#Preview {
    DebugContainerView {
        IncomeDivisionPropertiesInspect(data: try! .getExampleBudget())
    }
}
