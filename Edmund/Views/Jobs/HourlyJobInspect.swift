//
//  HourlyJobView.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftUI

/// The inspection view for Hourly Jobs. 
public struct HourlyJobInspect : View {
    public init(_ data: HourlyJob) {
        self.data = data
    }
    
    private var data: HourlyJob
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 90;
    private let labelMaxWidth: CGFloat = 100;
#else
    private let labelMinWidth: CGFloat = 100;
    private let labelMaxWidth: CGFloat = 110;
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
                Text("Hourly Rate:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.hourlyRate, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            
            GridRow {
                Text("Average Hours:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.avgHours, format: .number.precision(.fractionLength(2)))
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
    DebugContainerView {
        ElementInspector(data: HourlyJob.exampleJob)
    }
}
