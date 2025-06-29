//
//  BillEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI
import SwiftData

/// The inspect view for Bills. 
public struct BillInspect : View {
    private var data: Bill;
    public init(_ data: Bill) {
        self.data = data;
    }
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    public let minWidth: CGFloat = 110;
    public let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            BillBaseInspect(target: data, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.kind.name)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ElementInspector(data: Bill.exampleBills[0])
        .modelContainer(Containers.debugContainer)
}
