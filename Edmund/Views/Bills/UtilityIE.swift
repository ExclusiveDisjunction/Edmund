//
//  UtilityVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI
import SwiftData
import Charts

struct UtilityInspect : View, ElementInspectorView {
    typealias For = Utility;
    
    @Bindable var bill: Utility;
    @State private var showingSheet = false;
    @State private var showingChart = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    init(_ bill: Utility) {
        self.bill = bill;
    }
    
#if os(macOS)
    let minWidth: CGFloat = 60;
    let maxWidth: CGFloat = 70;
#else
    let minWidth: CGFloat = 90;
    let maxWidth: CGFloat = 95;
#endif
    
    var body: some View {
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

struct UtilityEdit : View, ElementEditorView {
    typealias For = Utility;
    
    @Bindable var snapshot: UtilitySnapshot;
    @State private var showingSheet = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    init(_ snapshot: UtilitySnapshot) {
        self.snapshot = snapshot
    }
    
#if os(macOS)
    let minWidth: CGFloat = 80;
    let maxWidth: CGFloat = 90;
#else
    let minWidth: CGFloat = 110;
    let maxWidth: CGFloat = 120;
#endif
    
    var body: some View {
        Grid {
            BillBaseEditor(editing: snapshot.base, minWidth: minWidth, maxWidth: maxWidth)
            
            GridRow {
                VStack {
                    Text("Price:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        .foregroundStyle(
                            snapshot.base.errors.contains(.children) || snapshot.base.errors.contains(.amount) ? .red : .primary
                        )
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Text(snapshot.amount, format: .currency(code: currencyCode))
                        Spacer()
                    }
                    HStack {
                        Button(action: { showingSheet = true } ) {
                            Label("Edit Datapoints...", systemImage: "pencil")
                        }
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            LongTextEditWithLabel(value: $snapshot.base.notes, minWidth: minWidth, maxWidth: maxWidth)
        }.sheet(isPresented: $showingSheet) {
            UtilityEntriesEdit(snapshot: snapshot)
        }
    }
    
}

typealias UtilityIE = ElementIE<Utility>;

#Preview {
    UtilityIE(Utility.exampleUtility[0], isEdit: false).modelContainer(Containers.debugContainer)
}
