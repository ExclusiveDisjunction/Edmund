//
//  BillBaseVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI

@Observable
class BillBaseSnapshot: Identifiable, Hashable, Equatable {
    init<T>(_ from: T) where T: BillBase {
        self.name = from.name
        self.startDate = from.startDate
        self.hasEndDate = from.endDate != nil
        self.endDate = from.endDate ?? Date.now
        self.period = from.period
        self.company = from.company
        self.hasLocation = from.location != nil
        self.location = from.location ?? String()
        self.notes = from.notes
        self.id = UUID()
    }
    
    var id: UUID;
    var name: String;
    var startDate: Date;
    var hasEndDate: Bool;
    var endDate: Date;
    var period: BillsPeriod;
    var company: String;
    var hasLocation: Bool;
    var location: String;
    var notes: String;
    
    var errors = Set<InvalidBillFields>();
    
    var isValid: Bool {
        Bill.validate(name: name, startDate: startDate, endDate: hasEndDate ? endDate : nil, company: company, location: hasLocation ? location : nil, invalid: &errors)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
        hasher.combine(company)
        hasher.combine(location)
        hasher.combine(notes)
    }
    static func ==(lhs: BillBaseSnapshot, rhs: BillBaseSnapshot) -> Bool {
        lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.period == rhs.period && lhs.company == rhs.company && lhs.location == rhs.location && lhs.notes == rhs.notes
    }
    
    func apply<T>(_ to: T) where T: BillBase {
        to.update(self)
    }
}

struct BillBaseInspect : View {
    var target: any BillBase
    let minWidth: CGFloat;
    let maxWidth: CGFloat;
    
    var body: some View {
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
                    Text("No Company")
                }
                Spacer()
            }
        }
        
        Divider()
        
        GridRow {
            Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Text(target.period.name)
                Spacer()
            }
        }
        
        Divider()
    }
}
struct BillBaseEditor : View {
    @Bindable var editing: BillBaseSnapshot;
    let minWidth: CGFloat;
    let maxWidth: CGFloat;
    
    var body: some View {
        GridRow {
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                .foregroundStyle(editing.errors.contains(.name) ? Color.red : Color.primary)
            
            HStack {
                TextField("Name", text: $editing.name)
                    .textFieldStyle(.roundedBorder)
                Spacer()
            }
        }
        
        Divider()
        
        GridRow {
            Text("Start Date:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                .foregroundStyle(editing.errors.contains(.dates) ? Color.red : Color.primary)
            
            HStack {
                DatePicker("Start", selection: $editing.startDate, displayedComponents: .date)
                    .labelsHidden()
                Spacer()
            }
        }
        
        GridRow {
            Text("Has End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Toggle("Has End Date", isOn: $editing.hasEndDate).labelsHidden()
                Spacer()
            }
        }
        
        if editing.hasEndDate {
            GridRow {
                Text("End Date:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    .foregroundStyle(editing.errors.contains(.dates) ? Color.red : Color.primary)
                
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
                .foregroundStyle(editing.errors.contains(.company) ? Color.red : Color.primary)
            
            HStack {
                TextField("Company", text: $editing.company)
                Spacer()
            }
        }
        
        GridRow {
            Text("Has Location:")
                .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Toggle("Has Location", isOn: $editing.hasLocation).labelsHidden()
                Spacer()
            }
        }
        
        if editing.hasLocation {
            GridRow {
                Text("Location:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    .foregroundStyle(editing.errors.contains(.location) ? Color.red : Color.primary)
                
                HStack {
                    TextField("Location", text: $editing.location)
                    Spacer()
                }
            }
        }
        
        Divider()
        
        GridRow {
            Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Picker("Frequency", selection: $editing.period) {
                    ForEach(BillsPeriod.allCases, id: \.id) { period in
                        Text(period.name).tag(period)
                    }
                }.labelsHidden()
                Spacer()
            }
        }
        
        Divider()
    }
}

struct LongTextEditWithLabel : View {
    @Binding var value: String;
    let minWidth: CGFloat;
    let maxWidth: CGFloat;
    
    var body: some View {
        GridRow {
            VStack {
                Text("Notes:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                Spacer()
            }
            
            TextEditor(text: $value).multilineTextAlignment(.leading).frame(maxHeight: 150)
        }
    }
}

#Preview {
    let target = Bill.exampleSubscriptions[0]
    let manifest = BillBaseSnapshot(target)
    
    Grid {
        BillBaseInspect(target: target, minWidth: 70, maxWidth: 80)
        
        Divider()
        
        BillBaseEditor(editing: manifest, minWidth: 70, maxWidth: 80)
    }
}
