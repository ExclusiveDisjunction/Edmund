//
//  BillEditor.swift
//  Edmund
//
//  Created by Hollan Sellars on 3/26/25.
//

import SwiftUI

/// The inspect view for Bills. 
public struct BillInspect : View {
    private var data: Bill;
    public init(_ data: Bill) {
        self.data = data;
    }
    
    @State private var showingSheet = false;
    @State private var showingChart = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    public let minWidth: CGFloat = 110;
    public let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Name:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.name)
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Start Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.startDate.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                }
            }
            
            GridRow {
                Text("End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    if let endDate = data.endDate {
                        Text(endDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    else {
                        Text("No end date").italic()
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Company:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.company)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Location:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.location ?? "No Location")
                    Spacer()
                }
            }
            
            GridRow {
                Text("Autopay:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.autoPay ? "Yes" : "No")
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.period.display)
                    Spacer()
                }
            }
            
            Divider()
            
            if horizontalSizeClass == .compact {
                GridRow {
                    Text("").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Button(action: { showingSheet = true } ) {
                            Label("Inspect History", systemImage: "info.circle")
                        }
                        Button(action: { showingChart = true } ) {
                            Label("Price over Time", systemImage: "chart.bar")
                        }
                        Spacer()
                    }
                }
            }
            else {
                GridRow {
                    Text("").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Button(action: { showingSheet = true } ) {
                            Label("History", systemImage: "info.circle")
                        }
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Button(action: { showingChart = true } ) {
                            Label("Price over Time", systemImage: "chart.bar")
                        }
                        Spacer()
                    }
                }
            }
            
            
            
            Divider()
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.amount, format: .currency(code: currencyCode))
                    Spacer()
                }
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(data.kind.display)
                    Spacer()
                }
            }
        }.sheet(isPresented: $showingSheet) {
            BillDatapointInspect(over: data)
        }.sheet(isPresented: $showingChart) {
            BillDatapointGraph(source: data)
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<Bill>(sortDescriptors: []) var bills: FetchedResults<Bill>;
    
    ElementInspector(data: bills[0])
}
