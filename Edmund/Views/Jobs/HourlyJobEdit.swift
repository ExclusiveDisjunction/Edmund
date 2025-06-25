//
//  HourlyJobEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/24/25.
//

import SwiftUI

/// The edit view for Hourly Jobs. 
public struct HourlyJobEdit : View, ElementEditorView {
    public typealias For = HourlyJob
    
    public init(_ data: HourlyJobSnapshot) {
        self.snapshot = data
    }
    
    @Bindable private var snapshot: HourlyJobSnapshot;
    @State private var showingTax: Bool = false;
    
#if os(macOS)
    private let labelMinWidth: CGFloat = 100;
    private let labelMaxWidth: CGFloat = 110;
#else
    private let labelMinWidth: CGFloat = 145;
    private let labelMaxWidth: CGFloat = 155;
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
                
                CurrencyField(snapshot.hourlyRate)
            }
            
            GridRow {
                Text("Average Hours:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                TextField("Average Hours", value: $snapshot.avgHours, format: .number.precision(.fractionLength(2)))
                    .textFieldStyle(.roundedBorder)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }
            
            GridRow {
                Text("Tax Rate:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    TextField("", value: $snapshot.taxRate, format: .percent)
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                    Button("...", action: {
                        showingTax = true
                    }).buttonStyle(.bordered)
                }
            }
        }.sheet(isPresented: $showingTax) {
            JobTaxEstimator(output: $snapshot.taxRate)
        }
    }
}

#Preview {
    ElementEditor(HourlyJob(), adding: true)
        .modelContainer(Containers.debugContainer)
}
