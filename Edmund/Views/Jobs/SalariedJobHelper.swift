//
//  SalariedJobHelper.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/10/25.
//

import SwiftUI

/// A view used to help determine the paycheck amount of a salaried job.
/// This will write back into the output passed when created, so that the owning view will have proper updated values.
public struct SalariedJobHelper : View {
    public init(output: CurrencyValue, isSheet: Bool = true) {
        self.output = output
        self.isSheet = isSheet
    }
    
    @Bindable private var output: CurrencyValue;
    @Bindable private var wage: CurrencyValue = .init();
    @State private var hours: Decimal = 50;
    @State private var perPeriod: TimePeriods = .weekly;
    @State private var outputPeriod: TimePeriods = .weekly;
    private var grossPay: Decimal {
        wage.rawValue * hours
    }
    private var paycheckPay: Decimal {
        self.grossPay * perPeriod.conversionFactor(outputPeriod)
    }
    private let isSheet: Bool;
    
    @Environment(\.dismiss) private var dismiss;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func submit() {
        output.rawValue = paycheckPay
        output.format(context: currencyCode)
    }
    
#if os(macOS)
    private let minWidth: CGFloat = 70;
    private let maxWidth: CGFloat = 80;
#else
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#endif
    
    public var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text("Wage:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    CurrencyField(wage)
                }
                
                GridRow {
                    Text("Hours:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        TextField("", value: $hours, format: .number.precision(.fractionLength(2)))
                            .textFieldStyle(.roundedBorder)
#if os(iOS)
                            .keyboardType(.decimalPad)
#endif
                        Text("/")
                        
                        Picker("", selection: $perPeriod) {
                            ForEach(TimePeriods.allCases, id: \.id) { period in
                                Text(period.perName).tag(period)
                            }
                        }.labelsHidden()
                        
                        TooltipButton("This period is how many hours you work in this period. For example, 50 hours per week.")
                    }
                }
                
                GridRow {
                    Text("Gross Pay:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(grossPay, format: .currency(code: currencyCode))
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Paycheck:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Text(paycheckPay, format: .currency(code: currencyCode))
                        
                        Text("/")
                        
                        Picker("", selection: $outputPeriod) {
                            ForEach(TimePeriods.allCases, id: \.id) { period in
                                Text(period.perName).tag(period)
                            }
                        }.labelsHidden()
                        
                        TooltipButton("This period is how often you get paid by your job.")
                    }
                }
            }
            
            if isSheet {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel", action: { dismiss() })
                        .buttonStyle(.bordered)
                    
                    Button("Ok", action: submit)
                        .buttonStyle(.borderedProminent)
                }
            }
        }.padding()
    }
}

#Preview {
    let value = CurrencyValue()
    
    SalariedJobHelper(output: value, isSheet: true)
}
