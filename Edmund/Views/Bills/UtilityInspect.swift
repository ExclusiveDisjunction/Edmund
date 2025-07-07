//
//  UtilityInspect.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData
import EdmundCore

public struct UtilityInspect : View {
    @Bindable public var bill: Utility;
    @State private var showingSheet = false;
    @State private var showingChart = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    public init(_ bill: Utility) {
        self.bill = bill;
    }
    
#if os(macOS)
    private let minWidth: CGFloat = 60;
    private let maxWidth: CGFloat = 70;
#else
    private let minWidth: CGFloat = 90;
    private let maxWidth: CGFloat = 95;
#endif
    
    public var body: some View {
        Grid {
            BillBaseInspect(target: bill, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                VStack {
                    Text("Price:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Text(bill.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                    HStack {
                        Button(action: { showingSheet = true } ) {
                            Label("Inspect Datapoints...", systemImage: "info.circle")
                        }
                        Button(action: { showingChart = true } ) {
                            Label("Price over Time", systemImage: "chart.bar")
                        }
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            LongTextEditWithLabel(value: $bill.notes, minWidth: minWidth, maxWidth: maxWidth)
        }.sheet(isPresented: $showingSheet) {
            UtilityEntriesInspect(children: bill.children)
        }.sheet(isPresented: $showingChart) {
            VStack {
                UtilityEntriesGraph(source: bill)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button("Ok", action: { showingChart = false } ).buttonStyle(.borderedProminent)
                }
            }.padding()
        }
    }
}


#Preview {
    DebugContainerView {
        ElementInspector(data: Utility())
    }
}
