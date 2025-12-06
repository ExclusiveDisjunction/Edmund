//
//  SalariedJobEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The edit view for Salaried Jobs.
public struct SalariedJobEdit : View {
    public init(_ snapshot: SalariedJobSnapshot) {
        self.snapshot = snapshot;
    }
    
    @Bindable private var snapshot: SalariedJobSnapshot;
    @State private var showingTax: Bool = false;
    @State private var showingHelper: Bool = false;
    
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
                Text("Gross Pay:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                HStack {
                    CurrencyField(snapshot.grossAmount)
                    
                    Button("...", action: {
                        showingHelper = true
                    }).buttonStyle(.bordered)
                }
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
        }.sheet(isPresented: $showingHelper) {
            SalariedJobHelper(output: snapshot.grossAmount)
        }
    }
}

#Preview {
    DebugContainerView {
        ElementEditor(SalariedJob.exampleJob, adding: false)
    }
}
