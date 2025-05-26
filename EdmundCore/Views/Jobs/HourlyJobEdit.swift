//
//  HourlyJobEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftUI

public struct HourlyJobEdit : View, ElementEditorView {
    public typealias For = HourlyJob
    
    public init(_ data: HourlyJobSnapshot) {
        self.snapshot = data
    }
    
    @Bindable private var snapshot: HourlyJobSnapshot;
    
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
                
                TextField("Position", text: $snapshot.position)
                    .textFieldStyle(.roundedBorder)
            }
            
            GridRow {
                Text("Company:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                TextField("Company", text: $snapshot.company)
                    .textFieldStyle(.roundedBorder)
            }
            
            GridRow {
                Text("Hourly Rate:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                CurrencyField($snapshot.hourlyRate)
            }
            
            GridRow {
                Text("Average Hours:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                TextField("Average Hours", value: $snapshot.avgHours, format: .number.precision(.fractionLength(2)))
            }
        }
    }
}

#Preview {
    ElementEditor(HourlyJob(), adding: true)
        .modelContainer(Containers.debugContainer)
        .padding()
}
