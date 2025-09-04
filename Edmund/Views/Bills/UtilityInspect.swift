//
//  UtilityInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct UtilityInspect : View {
    @Bindable public var bill: Utility;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public init(_ bill: Utility) {
        self.bill = bill;
    }
    
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 95;
#endif
    
    public var body: some View {
        Grid {
            BillBaseInspect(target: bill, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                Text("Price:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(bill.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
        }
    }
}


#Preview {
    DebugContainerView {
        ElementInspector(data: Utility())
    }
}
