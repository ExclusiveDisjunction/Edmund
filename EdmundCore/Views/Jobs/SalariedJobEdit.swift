//
//  SalariedJobEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The edit view for Salaried Jobs.
public struct SalariedJobEdit : ElementEditorView {
    public typealias For = SalariedJob;
    
    public init(_ snapshot: SalariedJobSnapshot) {
        self.snapshot = snapshot;
    }
    
    @Bindable private var snapshot: SalariedJobSnapshot;
    
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
                
                CurrencyField(snapshot.grossAmount)
            }
            
            GridRow {
                Text("Tax Rate:")
                    .frame(minWidth: labelMinWidth, maxWidth: labelMaxWidth, alignment: .trailing)
                
                TextField("", value: $snapshot.taxRate, format: .percent)
            }
        }
    }
}

#Preview {
    ElementEditor(SalariedJob(), adding: true)
        .modelContainer(Containers.debugContainer)
}
