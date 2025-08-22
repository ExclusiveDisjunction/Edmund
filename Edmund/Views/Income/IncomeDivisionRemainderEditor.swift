//
//  BudgetRemainderEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/28/25.
//

import SwiftUI
import SwiftData
import EdmundCore

struct IncomeDivisionRemainderEditor : View {
    @Bindable var remainder: DevotionSnapshotBase;
    @Binding var hasRemainder: Bool;
    var remainderValue: Decimal;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
#if os(macOS)
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 100;
#else
    private let minWidth: CGFloat = 120;
    private let maxWidth: CGFloat = 130;
#endif
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text("Use Remainder:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Toggle("", isOn: $hasRemainder)
                            .labelsHidden()
                        
                        TooltipButton("When this is on, any remaining balance not used by other devotions will be used here.")
                        Spacer()
                    }
                }
                
                if hasRemainder {
                    GridRow {
                        Text("Name:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        TextField("", text: $remainder.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    GridRow {
                        Text("Group:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        Picker("", selection: $remainder.group) {
                            ForEach(DevotionGroup.allCases) { group in
                                Text(group.display).tag(group)
                            }
                        }.labelsHidden()
                    }
                    
                    GridRow {
                        Text("Account:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        ElementPicker($remainder.account)
                    }
                    
                    GridRow {
                        Text("Used Amount:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        HStack {
                            Text(remainderValue, format: .currency(code: currencyCode))
                            Spacer()
                        }
                    }
                }
            }
            
            Spacer()
        }.padding()
    }
}
