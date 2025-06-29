//
//  SalariedJobinspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The edit view for Salaried Jobs. 
public struct SalariedJobInspector : View {
    public init(_ data: SalariedJob) {
        self.data = data
    }
    
    private var data: SalariedJob;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 70;
    private let labelMaxWidth: CGFloat = 80;
#else
    private let labelMinWidth: CGFloat = 80;
    private let labelMaxWidth: CGFloat = 90;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Position:", comment: "Job position")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.position)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Company:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.company)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Gross Pay:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.grossAmount, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            
            GridRow {
                Text("Tax Rate:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.taxRate, format: .percent)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ElementInspector(data: SalariedJob())
        .modelContainer(Containers.debugContainer)
}
