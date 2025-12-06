//
//  BudgetPropertiesInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData

struct IncomeDivisionPropertiesInspect : View {
    var data: IncomeDivision;
    let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    
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
                        ElementDisplayer(value: data.depositTo)
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Finalized:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(data.isFinalized ? "Yes" : "No")
                        TooltipButton("Finalized income divisions create transactions in the ledger. These transactions cannot be modified if you modify the income division, so you cannot edit a finalized income division.")
                        Spacer()
                    }
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
    @Previewable @Query var income: [IncomeDivision];
    
    DebugContainerView {
        IncomeDivisionPropertiesInspect(data: income[0], isSheet: false)
    }
}
