//
//  UtilityEntryVE.swift
//  Edmund
//
//  Created by Hollan Sellars on 4/21/25.
//

import Foundation
import SwiftUI
import SwiftData
import Charts

@Observable
class UtilityEntrySnapshot: Identifiable, Hashable, Equatable {
    init(_ from: UtilityEntry) {
        self.amount = from.amount
        self.date = from.date
        self.id = UUID()
    }
    init(amount: Decimal, date: Date, id: UUID = UUID()) {
        self.id = id
        self.amount = amount
        self.date = date
    }
    init() {
        self.id = UUID()
        self.amount = 0
        self.date = Date.now
    }
    
    var id: UUID;
    var amount: Decimal;
    var date: Date;
    var isSelected: Bool = false;
    
    var isValid: Bool {
        amount >= 0
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(date)
    }
    static func ==(lhs: UtilityEntrySnapshot, rhs: UtilityEntrySnapshot) -> Bool {
        lhs.amount == rhs.amount && lhs.date == rhs.date
    }
}

struct UtilityEntriesInspect : View {
    var children: [UtilityEntry];
    @State private var selected = Set<UtilityEntry.ID>();
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass;
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            
            if horizontalSizeClass == .compact {
                List(children, selection: $selected) { child in
                    HStack {
                        Text(child.amount, format: .currency(code: currencyCode))
                        Text("On", comment: "[Amount] on [Date]")
                        Text(child.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            else {
                Table(children, selection: $selected) {
                    TableColumn("Amount") { child in
                        Text(child.amount, format: .currency(code: currencyCode))
                    }
                    TableColumn("Date") { child in
                        Text(child.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }
        .padding()
#if os(macOS)
        .frame(minHeight: 350)
#endif
    }
}
struct UtilityEntriesEditRow : View {
    @Bindable var child: UtilityEntrySnapshot
    let currencyCode: String;
    
    var body: some View {
        GridRow {
            Toggle("Select", isOn: $child.isSelected).labelsHidden()//.toggleStyle(CheckboxToggleStyle())
            TextField("Amount", value: $child.amount, format: .currency(code: currencyCode))
                .labelsHidden()
                .foregroundStyle(child.amount < 0 ? .red : .primary)
            DatePicker("", selection: $child.date, displayedComponents: .date).labelsHidden()
        }
    }
}
struct UtilityEntriesEdit : View {
    @Bindable var snapshot: UtilitySnapshot;
    @Environment(\.dismiss) private var dismiss;
    
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD";
    
    private func remove_selected() {
        snapshot.children.removeAll(where: { $0.isSelected } )
    }
    private func add_new() {
        snapshot.children.append(.init(amount: 0, date: Date.now))
    }
    
    var body: some View {
        VStack {
            Text("Datapoints").font(.title2)
            HStack {
                Button(action: add_new) {
                    Label("Add", systemImage: "plus").buttonStyle(.bordered)
                }
                Button(action: remove_selected) {
                    Label("Delete", systemImage: "trash").foregroundStyle(.red).buttonStyle(.bordered)
                }
                Spacer()
            }
            
            ScrollView {
                Grid {
                    GridRow {
                        Text("")
                        Text("Amount")
                        Text("Date")
                    }
                    
                    ForEach(snapshot.children, id: \.id) { child in
                        UtilityEntriesEditRow(child: child, currencyCode: currencyCode)
                    }
                }
            }.frame(minHeight: 300, maxHeight: .infinity)
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok", action: { dismiss() } ).buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}
struct UtilityEntriesGraph : View {
    var source: Utility;
    
    var body: some View {
        VStack {
            Text("Price Over Time").font(.title2)
            
            HStack {
                Chart {
                    ForEach(source.children.sorted(by: { $0.date < $1.date } ), id: \.id) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Amount", point.amount),
                            series: .value("Name", source.name)
                        )
                    }
                }.frame(minHeight: 250)
                
                Text("Price").rotationEffect(.degrees(90))
            }
            
            Text("Month")
        }
    }
}

#Preview {
    let bill = Utility.exampleUtility[0];
    ScrollView {
        VStack {
            UtilityEntriesGraph(source: bill)
            Divider()
            UtilityEntriesEdit(snapshot: .init(bill))
            Divider()
            UtilityEntriesInspect(children: bill.children)
        }.padding()
    }
}
