//
//  BillBaseVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI
import EdmundCore

/// A collection of common rows used for `BillInspect` and `UtilityInspect`, specifically for inspection.
struct BillBaseInspect : View {
    /// The target value to inspect
    var target: any BillBase
    /// The minimum column width used by the labels.
    let minWidth: CGFloat;
    /// The maximum column width used by the labels.
    let maxWidth: CGFloat;
    
    var body: some View {
        GridRow {
            Text("Name:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Text(target.name)
                Spacer()
            }
        }
        
        Divider()
        
        GridRow {
            Text("Start Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Text(target.startDate.formatted(date: .abbreviated, time: .omitted))
                Spacer()
            }
        }
        
        GridRow {
            Text("End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                if let endDate = target.endDate {
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
                Text(target.company)
                Spacer()
            }
        }
        
        GridRow {
            Text("Location:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                if let location = target.location {
                    Text(location)
                }
                else {
                    Text("No location").italic()
                }
                Spacer()
            }
        }
        
        GridRow {
            Text("Autopay:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Text(target.autoPay ? "Yes" : "No")
                Spacer()
            }
        }
        
        Divider()
        
        GridRow {
            Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Text(target.period.display)
                Spacer()
            }
        }
        
        Divider()
    }
}

/// A collection of common rows used for `BillEdit` and `UtilityEdit`, specifically for editing.
struct BillBaseEditor : View {
    /// The target snapshot
    @Bindable var editing: BillBaseSnapshot;
    /// The minimum column width used by the labels.
    let minWidth: CGFloat;
    /// The maximum column width used by the labels.
    let maxWidth: CGFloat;
    
    var body: some View {
        GridRow {
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            TextField("Name", text: $editing.name)
                .textFieldStyle(.roundedBorder)
        }
        
        Divider()
        
        GridRow {
            Text("Start Date:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                DatePicker("", selection: $editing.startDate, displayedComponents: .date)
                    .labelsHidden()
                Spacer()
            }
        }
        
        GridRow {
            Text("Has End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Toggle("", isOn: $editing.hasEndDate).labelsHidden()
                Spacer()
            }
        }
        
        if editing.hasEndDate {
            GridRow {
                Text("End Date:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("End", selection: $editing.endDate, displayedComponents: .date)
                        .labelsHidden()
                    
                    Spacer()
                }
            }
        }
        
        Divider()
        
        GridRow {
            Text("Company:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            TextField("Company", text: $editing.company)
                .textFieldStyle(.roundedBorder)
        }
        
        GridRow {
            Text("Has Location:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Toggle("", isOn: $editing.hasLocation).labelsHidden()
                Spacer()
            }
        }
        
        if editing.hasLocation {
            GridRow {
                Text("Location:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                TextField("Location", text: $editing.location)
                    .textFieldStyle(.roundedBorder)
            }
        }
        
        GridRow {
            Text("Autopay:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            
            HStack {
                Toggle("", isOn: $editing.autoPay)
                    .labelsHidden()
                Spacer()
            }
        }
        
        Divider()
        
        GridRow {
            Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Picker("Frequency", selection: $editing.period) {
                    ForEach(TimePeriods.allCases, id: \.id) { period in
                        Text(period.display).tag(period)
                    }
                }.labelsHidden()
                Spacer()
            }
        }
        
        Divider()
    }
}

/// A simple abstraction for a row  that uses a large `TextEditor` over some value.
struct LongTextEditWithLabel : View {
    @Binding var value: String;
    let minWidth: CGFloat;
    let maxWidth: CGFloat;
    
    var body: some View {
        GridRow {
            VStack {
                Text("Notes:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                Spacer()
            }
            
            TextEditor(text: $value)
                .multilineTextAlignment(.leading)
                .frame(maxHeight: 150)
        }
    }
}

#Preview {
    let target = Bill.exampleSubscriptions[0]
    let manifest = BillBaseSnapshot(target)
    
    ScrollView {
        Grid {
            BillBaseInspect(target: target, minWidth: 80, maxWidth: 90)
            
            Divider()
            
            BillBaseEditor(editing: manifest, minWidth: 90, maxWidth: 100)
        }.padding()
    }
}
