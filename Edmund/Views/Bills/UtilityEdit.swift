//
//  UtilityVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI
import SwiftData
import EdmundCore

/// The edit view for Utilities.
public struct UtilityEdit : View {
    @Bindable public var snapshot: UtilitySnapshot;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public init(_ snapshot: UtilitySnapshot) {
        self.snapshot = snapshot
    }
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            BillBaseEditor(editing: snapshot, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                Text("Price:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(snapshot.amount, format: .currency(code: currencyCode))
                    
                    Spacer()
                }
            }
        }
    }
    
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    ElementEditor(Utility(), adding: false)
}
