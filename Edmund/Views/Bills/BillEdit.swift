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
    
    @NullableValue<Bill, String> private var location: Binding<Bool>;
    @NullableValue<Bill, Date> private var endDate: Binding<Bool>;
    
    public init(_ data: Bill) {
        self._data = .init(wrappedValue: data)
        self._location = .init(data, \.location, "")
        self._endDate = .init(data, \.endDate, .now)
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
                    Toggle("", isOn: endDate).labelsHidden()
                    Spacer()
                }
            }
        
            GridRow {
                Text("End Date:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("End", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!endDate.wrappedValue)
                    
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
                    Toggle("", isOn: location).labelsHidden()
                    Spacer()
                }
            }
            
            GridRow {
                Text("Location:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("Location", text: $location)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!location.wrappedValue)
            }
            
            GridRow {
                Text("Autopay:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                
                HStack {
                    Toggle("", isOn: $data.autoPay)
                        .labelsHidden()
                    Spacer()
                }
            }
            
            Divider()
            
            GridRow {
                Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    EnumPicker(value: $data.period)
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
                
                CurrencyField($data.amount, currencyCode: currencyCode)
            }
            
            GridRow {
                Text("Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    EnumPicker(value: $data.kind)
                    
                    TooltipButton("Subscriptions can usually be canceled whenever, while bills have stricter requirements.")
                }
            }
        }.sheet(isPresented: $showingSheet) {
            BillDatapointEdit(bill: data)
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<Bill>(sortDescriptors: []) var bills: FetchedResults<Bill>;
    
    ElementEditor(editManifest: ElementEditManifest(using: DataStack.shared.currentContainer, from: bills[0]))
}
