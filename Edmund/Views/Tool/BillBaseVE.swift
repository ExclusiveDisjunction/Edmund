//
//  BillBaseVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/7/25.
//

import Foundation
import SwiftUI

@Observable
class BillBaseManifest: Identifiable, Hashable, Equatable {
    init<T>(_ from: T) where T: BillBase {
        self.name = from.name
        self.startDate = from.startDate
        self.endDate = from.endDate
        self.period = from.period
        self.id = UUID()
    }
    
    var id: UUID;
    var name: String;
    var startDate: Date;
    var endDate: Date?;
    var period: BillsPeriod;
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(period)
    }
    static func ==(lhs: BillBaseManifest, rhs: BillBaseManifest) -> Bool {
        lhs.name == rhs.name && lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate && lhs.period == rhs.period
    }
    
    func apply<T>(_ to: inout T) where T: BillBase {
        to.update(self)
    }
}

struct BillBaseViewer : View {
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
        
        GridRow {
            Text("Frequency:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Text(target.period.name)
                Spacer()
            }
        }
    }
}
struct BillBaseEditor : View {
    @Bindable var editing: BillBaseManifest;
    let minWidth: CGFloat;
    let maxWidth: CGFloat;
    
    var body: some View {
        GridRow {
            Text("Name:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                TextField("Name", text: $editing.name).textFieldStyle(.roundedBorder)
                Spacer()
            }
        }
        
        GridRow {
            Text("Start Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                DatePicker("Start", selection: $editing.startDate, displayedComponents: .date).labelsHidden()
                Spacer()
            }
        }
        
        GridRow {
            Text("Has End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
            
            HStack {
                Toggle("Has End Date", isOn: Binding(get: {editing.endDate != nil }, set: { editing.endDate = $0 ? Date.now : nil } ) ).labelsHidden()
                Spacer()
            }
        }
        
        if let endDate = editing.endDate {
            GridRow {
                Text("End Date:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DatePicker("End", selection: Binding(get: { endDate }, set: {editing.endDate = $0 } ), displayedComponents: .date).labelsHidden()
                    
                    Spacer()
                }
            }
        }
        
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
    }
}

#Preview {
    let target = Bill.exampleSubscriptions[0]
    let manifest = BillBaseManifest(target)
    
    Grid {
        BillBaseViewer(target: target, minWidth: 70, maxWidth: 80)
        
        Divider()
        
        BillBaseEditor(editing: manifest, minWidth: 70, maxWidth: 80)
    }
}
