//
//  JobTaxEstimator.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/27/25.
//

import SwiftUI
import EdmundCore

/// A row used in the `JobTaxEstimator`, specfically holding the gross and net amounts.
@Observable
public class JobTaxRow : Identifiable {
    init(id: UUID = UUID()) {
        self.gross = .init()
        self.net = .init();
        self.id = id
    }
    
    public var id: UUID;
    /// The gross pay amount
    public var gross: CurrencyValue;
    /// The net pay amount
    public var net: CurrencyValue;
    
    /// The tax rate computed from gross or net. This will always be between 0.0 -> 1.0
    public var taxRate: Decimal {
        if net >= gross {
            return 1;
        }
        else if net < 0 || gross < 0 {
            return 0;
        }
        else if net == 0 && gross == 0 {
            return 0;
        }
        else if net == 0 && gross > 0 {
            return 1;
        }
        else {
            return (1 - net.rawValue / gross.rawValue);
        }
    }
}

/// A tool window that can determine the average tax amount for a job, based on many pay checks.
public struct JobTaxEstimator : View {
    /// The destination of the resultant tax rate, if submitted.
    @Binding public var output: Decimal;
    /// The current rows
    @State private var data: [JobTaxRow] = [.init()];
    /// The selection from the table
    @State private var selection = Set<JobTaxRow.ID>();
    
    /// The total tax rate, computed from averaging the `data` parameter.
    private var totalTax : Decimal {
        data.reduce(Decimal(), { $0 + $1.taxRate } ) / Decimal(data.count)
    }
    
    @Environment(\.dismiss) private var dismiss;
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
    /// Stores the `totalTax` to the `output` & closes the window.
    private func apply() {
        output = totalTax;
        dismiss()
    }
    /// Appends a new element to the view.
    private func append() {
        withAnimation {
            data.append(.init())
        }
    }
    
    @ViewBuilder
    private func selContextMenu(_ selection: Set<JobTaxRow.ID>) -> some View {
        Button("Add", action: append)
        
        Button("Remove", action: {
            data.removeAll(where: { selection.contains($0.id) } )
        })
        .foregroundStyle(.red)
        .disabled(selection.isEmpty)
    }
    
    @ViewBuilder
    private var compact: some View {
        VStack {
            Text("Gross / Net -> Tax Rate")
            List(data, selection: $selection) { row in
                HStack {
                    CurrencyField(row.gross)
                    Text("/")
                    CurrencyField(row.net)
                    Image(systemName: "arrow.right")
                    Text(row.taxRate, format: .percent.precision(.fractionLength(3)))
                }.swipeActions(edge: .trailing) {
                    Button(action: {
                        withAnimation {
                            data.removeAll(where: { $0.id == row.id } )
                        }
                    }) {
                        Image(systemName: "trash")
                    }.tint(.red)
                }
            }.contextMenu(forSelectionType: JobTaxRow.ID.self, menu: selContextMenu)
        }
    }
    
    @ViewBuilder
    private var full : some View {
        Table(data, selection: $selection) {
            TableColumn("Gross Pay") { row in
                CurrencyField(row.gross)
            }
            TableColumn("Net Pay") { row in
                CurrencyField(row.net)
            }
            TableColumn("Tax Rate") { row in
                Text(row.taxRate, format: .percent.precision(.fractionLength(3)))
            }
        }.contextMenu(forSelectionType: JobTaxRow.ID.self, menu: selContextMenu)
    }
    
    public var body: some View {
        VStack {
            HStack {
                Text("Tax Estimator")
                    .font(.title2)
                
                Spacer()
                
                Button(action: append) {
                    Image(systemName: "plus")
                }.buttonStyle(.borderless)
#if os(iOS)
                EditButton()
#endif
            }
            
            if horizontalSizeClass == .compact {
                compact
            }
            else {
                full
                #if os(macOS)
                    .frame(minHeight: 200)
                #endif
            }
            
            HStack {
                Spacer()
                Text("Total Average Tax Rate:")
                Text(totalTax, format: .percent.precision(.fractionLength(3)))
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Cancel", action: { dismiss() } )
                    .buttonStyle(.bordered)
                
                Button("Ok", action: apply)
                    .buttonStyle(.borderedProminent)
            }
            
        }.padding()
    }
}

#Preview {
    var result: Decimal = 0.0;
    let binding = Binding(get: { result }, set: { result = $0 } )
    
    JobTaxEstimator(output: binding)
}
