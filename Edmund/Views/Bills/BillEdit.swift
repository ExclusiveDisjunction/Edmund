//
//  BillEdit.swift
//  Edmund
//
//  Created by Hollan Sellars on 5/26/25.
//

import SwiftUI
import SwiftData

/// The edit view for Bills.
public struct BillEdit : View {
    @StateObject private var data: Bill;
    @State private var showingSheet = false;
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    @State private var oldLocation: String;
    @State private var oldEndDate: Date;
    
    var hasLocation: Bool {
        get { data.location != nil }
        set {
            if newValue {
                data.location = oldLocation;
            }
            else {
                oldLocation = data.location ?? "";
                data.location = nil;
            }
        }
    }
    var hasEndDate: Bool {
        get { data.endDate != nil }
        set {
            if newValue {
                data.endDate = oldEndDate;
            }
        }
    }
    
    public init(_ data: Bill) {
        self._data = .init(wrappedValue: data)
        
    }
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("Name", text: $data.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            GridRow {
                Text("Start Date:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("", selection: $data.startDate, displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                }
            }
            
            GridRow {
                Text("Has End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Toggle("", isOn: $snapshot.hasEndDate).labelsHidden()
                    Spacer()
                }
            }
        
            GridRow {
                Text("End Date:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("End", selection: $snapshot.endDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!snapshot.hasEndDate)
                    
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Company:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("Company", text: $data.company)
                    .textFieldStyle(.roundedBorder)
            }
            
            GridRow {
                Text("Has Location:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Toggle("", isOn: $snapshot.hasLocation).labelsHidden()
                    Spacer()
                }
            }
            
            GridRow {
                Text("Location:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("Location", text: $snapshot.location)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!snapshot.hasLocation)
            }
            
            GridRow {
                Text("Autopay:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                
                HStack {
                    Toggle("", isOn: $snapshot.autoPay)
                        .labelsHidden()
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    EnumPicker(value: $snapshot.period)
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Button(action: { showingSheet = true } ) {
                        Label("Edit History", systemImage: "pencil")
                    }
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Amount:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                CurrencyField(snapshot.amount)
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    EnumPicker(value: $snapshot.kind)
                    
                    TooltipButton("Subscriptions can usually be canceled whenever, while bills have stricter requirements.")
                }
            }
        }.sheet(isPresented: $showingSheet) {
            BillHistoryEdit(snapshot: snapshot)
        }
    }
}

#Preview {
    DebugContainerView {
        ElementEditor(Bill(kind: .subscription), adding: false)
    }
}
